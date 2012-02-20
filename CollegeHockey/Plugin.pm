# CollegeHockey plugin.pm by Mike Meyer March 2008
#	Copyright (c) 2008
#	All rights reserved.
#
# DESCRIPTION
# This plugin adds College Hockey scores via the SuperDateTime Plugin API.  (Thanks Greg!)
# The data is parsed from espn.com whenever SuperDateTime does a data refresh.
#
# INSTALLATION
# This plugin requires the use of SlimServer 7.0 with SuperDateTime 5.5.0 or higher.
#
# FEEDBACK
# Please direct all feedback to Mike Meyer on the Slim Devices public forums at forums.slimdevices.com
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
#	02111-1307 USA
#
#

package Plugins::CollegeHockey::Plugin;

use strict;
use base qw(Slim::Plugin::Base);

use Scalar::Util qw(blessed);

use Slim::Utils::Prefs;
use Slim::Utils::Log;
use Plugins::CollegeHockey::Settings;

my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.collegehockey',
	'defaultLevel' => 'DEBUG',
	'description'  => getDisplayName(),
});

my $prefs = preferences('plugin.collegehockey');

my $errorCount = 0;

my $MyTeam1 = "None";
my $MyTeam2 = "None";

sub getDisplayName {
	return 'PLUGIN_SCREENSAVER_COLLEGEHOCKEY';
}

sub initPlugin {
	my $class = shift;

	$log->debug("Initializing...");
	
	$class->SUPER::initPlugin();
	
	Slim::Plugin::CollegeHockey::Settings->new;
	
	if ($prefs->get('pref_team1') eq '') {
		$prefs->set('pref_team1', $MyTeam1);
        }
	if ($prefs->get('pref_team2') eq '') {
		$prefs->set('pref_team2', $MyTeam2);
	}

	registerMe();
}

sub registerMe {
	if (defined($Plugins::SuperDateTime::Plugin::apiVersion)) {
		$log->info("Successfully registered CollegeHockey with SuperDateTime.");
		Plugins::SuperDateTime::Plugin::registerProvider(\&getCollegeHockey);
	}
	else {
		$log->info("SuperDateTime not yet loaded.  Will try again in 15 seconds.");
		Slim::Utils::Timers::setTimer(undef, Time::HiRes::time() + 15, \&registerMe);
	}
}

sub getCollegeHockey {
	my $timerObj = shift; #Should be undef, unless called from a timer
	my $client = shift;
	my $refreshItem = shift;
	
	my $url = 'http://sports.espn.go.com/ncaa/scoreboard?sport=mhockey';
	my $http = Slim::Networking::SimpleAsyncHTTP->new(\&gotCollegeHockey,
			\&Plugins::SuperDateTime::Plugin::gotErrorViaHTTP,
			{client => $client,
			 caller => 'getCollegeHockey',
			 callerProc => \&getCollegeHockey,
			 refreshItem => $refreshItem});
		
	#$log->info("aync request: $url");
	$http->get($url);
}

sub gotCollegeHockey {
	my $http = shift;
	
        my $AwayScore = '';
        my $AwayTeam = '';
        my $AwayRecord = '';
        my $HomeTeam = '';
        my $HomeScore = '';
        my $MyTeam1 = $prefs->get('pref_team1');
        my $MyTeam2 = $prefs->get('pref_team2');

        my $HomeRecord = '';
        my $Gametime = '';
        my $DisplayLength = '';
        
	my $params = $http->params();
	my $client = $params->{'client'};
	my $refreshItem = $params->{'refreshItem'};
	
	$log->info("got " . $http->url());

	my $content = $http->content();
    
 	my @ary=split /<div class="gameContainer/,$content; #break large string into array
 	#$log->info("@ary");
        
        for (@ary){if (/gameHeader".+?left:5px;">(.+?)<\/td.+?ncaa-small.+?left:5px;">(.+?)<\/td.+?li.+?>(.+?)<\/li/s) {
                     $AwayTeam = $1;
                     $HomeTeam = $2;
                     $Gametime = $3;
                     if (/teamScore.+?nowrap;">(.+?)<\/td>.+?teamScore.+?nowrap;">(.+?)<\/td>/s) {
                       $AwayScore = $1;
                       $HomeScore = $2;
                     }
                     #$log->info("$Gametime");
                     #$log->info("$AwayTeam");
                     #$log->info("$AwayScore");
                     #$log->info("$HomeTeam");
                     #$log->info("$HomeScore");
                     #$log->info("$MyTeam1");
                     #$log->info("$MyTeam2");

                     $HomeTeam =~ s/State/St./g;
                     $AwayTeam =~ s/State/St./g;

                     if (($MyTeam1 eq rtrim($AwayTeam)) || ($MyTeam1 eq rtrim($HomeTeam)) || ($MyTeam2 eq rtrim($AwayTeam)) ||  ($MyTeam2 eq rtrim($HomeTeam))) {
                             $Gametime =~ s/1st Period, End/E1/gi;
                             $Gametime =~ s/2nd Period, End/E2/gi;
                             $Gametime =~ s/3rd Period, End/E3/gi;
                             $Gametime =~ s/1st Period/\/1/g;
                             $Gametime =~ s/2nd Period/\/2/g;
                             $Gametime =~ s/3rd Period/\/3/g;
                             $Gametime =~ s/Final - OT/ FOT/g;
                             $Gametime =~ s/Final/ F/g;
                             $Gametime =~ s/ PM ET/pm/g;
                             
                             my $HomeTeam = rtrim($HomeTeam);
                             my $AwayTeam = rtrim($AwayTeam);
                             my $HomeTeam = &shortenCH($HomeTeam);
                             my $AwayTeam = &shortenCH($AwayTeam);

                             $DisplayLength = length($AwayTeam) + length($AwayScore) + length($HomeTeam) + length($HomeScore) + length($Gametime);
                             if ($Gametime !~ /pm/) {      # Current Game or Finished
                                if ($DisplayLength > '23') {
                                        Plugins::SuperDateTime::Plugin::addDisplayItem("College Hockey Scores", "College Hockey", "$AwayTeam $AwayScore @ $HomeTeam $HomeScore  $Gametime", 'L');
                                } else {
                                        Plugins::SuperDateTime::Plugin::addDisplayItem("College Hockey Scores", "College Hockey", "$AwayTeam $AwayScore @ $HomeTeam $HomeScore  $Gametime", 5);
                                }
                             }
                             else {  # Upcoming Game
                                   Plugins::SuperDateTime::Plugin::addDisplayItem("College Hockey Scores", "College Hockey", "$AwayTeam @ $HomeTeam-$Gametime", 5);
                             }
                     }
                }
        }
	Plugins::SuperDateTime::Plugin::refreshData(undef, $client, $refreshItem);
}

sub shortenCH {
	my $long = shift;

#	YOU CAN MODIFY THIS LIKE THE EXAMPLE BELOW TO SHORTEN YOUR TEAM NAMES...
	if ($long =~ m/^St. Cloud St.$/) { $long = 'SCSU';}
	elsif ($long=~ m/^Minnesota Duluth$/) { $long = 'UMD';}
	elsif ($long=~ m/^Minnesota$/) { $long = 'Gophers';}

	return $long;
}

sub rtrim($)
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

1;

__END__
