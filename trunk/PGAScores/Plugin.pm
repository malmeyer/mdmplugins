# PGAScores plugin.pm by Mike Meyer March 2008
#	Copyright (c) 2008
#	All rights reserved.
#
# DESCRIPTION
# This plugin adds the PGA leaderboard information of the current tournament to SuperDateTimes display of information.
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
# Dedicated to my uncle Wayne.
#

package Plugins::PGAScores::Plugin;

#use strict;

use base qw(Slim::Plugin::Base);

use Scalar::Util qw(blessed);

use File::Spec;
use FindBin qw($Bin);
use lib(File::Spec->catdir($Bin, 'Plugins','PGAScores'));

use Slim::Utils::Prefs;
use Slim::Utils::Log;
use Plugins::PGAScores::Settings;

my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.pgascores',
	'defaultLevel' => 'INFO',
	'description'  => getDisplayName(),
});

my $prefs = preferences('plugin.pgascores');

my $errorCount = 0;

my $TopPlayers = 5;
my $PlayerLimit = 10;
my $PlayerTracker1 = "Type Name Here";
my $PlayerTracker2 = "Type Name Here";
my $ChampTopPlayers = 5;
my $ChampPlayerLimit = 10;
my $ChampPlayerTracker1 = "Type Name Here";
my $ChampPlayerTracker2 = "Type Name Here";
my $ShowPGA = 1;
my $ShowChamp = 0;
my $TournamentName = '';
my $DefendingChamp = '';
my $TourneyStatus = '';
my $Player = '';
my $Position = '';
my $Score = '';
my $Thru = '';
my $Winnings = '';
my $PlayerTotal = '';

sub getDisplayName {
	return 'PLUGIN_SCREENSAVER_PGASCORES';
}

sub initPlugin {
	my $class = shift;

	$log->info("Initializing...");
	
	$class->SUPER::initPlugin();
	
	Slim::Plugin::PGAScores::Settings->new;

	if ($prefs->get('pref_tracker1') eq '') {
		$prefs->set('pref_tracker1', $PlayerTracker1);
        }
	if ($prefs->get('pref_tracker2') eq '') {
		$prefs->set('pref_tracker2', $PlayerTracker2);
	}
	if ($prefs->get('pref_topgolfers') eq '') {
		$prefs->set('pref_topgolfers', $TopPlayers);
        }
	if ($prefs->get('pref_maxgolfers') eq '') {
		$prefs->set('pref_maxgolfers', $PlayerLimit);
        }
        
	if ($prefs->get('pref_champtracker1') eq '') {
		$prefs->set('pref_champtracker1', $ChampPlayerTracker1);
        }
	if ($prefs->get('pref_champtracker2') eq '') {
		$prefs->set('pref_champtracker2', $ChampPlayerTracker2);
	}
	if ($prefs->get('pref_champtopgolfers') eq '') {
		$prefs->set('pref_champtopgolfers', $ChampTopPlayers);
        }
	if ($prefs->get('pref_champmaxgolfers') eq '') {
		$prefs->set('pref_champmaxgolfers', $ChampPlayerLimit);
        }
	if (($prefs->get('pref_showpga') eq '~') || ($prefs->get('pref_showpga') eq '')) {
		$prefs->set('pref_showpga', $ShowPGA);
        }
	if (($prefs->get('pref_showchamp') eq '~') || ($prefs->get('pref_showchamp') eq '')) {
		$prefs->set('pref_showchamp', $ShowChamp);
        }
	registerMe();
}

sub registerMe {
	if (defined($Plugins::SuperDateTime::Plugin::apiVersion)) {
		$log->info("Successfully registered PGAScores with SuperDateTime.");
		Plugins::SuperDateTime::Plugin::registerProvider(\&getPGAScores);
		Plugins::SuperDateTime::Plugin::registerProvider(\&getChampionScores);
	}
	else {
		$log->info("SuperDateTime not yet loaded.  Will try again in 15 seconds.");
		Slim::Utils::Timers::setTimer(undef, Time::HiRes::time() + 15, \&registerMe);
	}
}

sub sendToJiveFinal {
        my %pgaHash;
        my $zero_num;
        my $XPGAPlayer;
        my $XPGAPosition;
        #my $XPGAWinnings;
        #my $XPGAScore;
        #my $XPGAThru;
        #my $XPGATournamentName;
        
        
        $XPGAPlayer = "%XPlayer".$PlayerTotal;
        $XPGAPosition = "%XPosition".$PlayerTotal;
        #$XPGAWinnings = "%XWinnings".$PlayerTotal;
        #$XPGAScore = "%XScore".$PlayerTotal;
        #$XPGAThru = "%XThru".$PlayerTotal;
        
        $zero_num = sprintf("%03d", $PlayerTotal);  # Needed to pad with leading zeros to sort right
        
        $pgaHash{'sport'} = $TournamentName;
	$pgaHash{'gameID'} = $zero_num;
	#$pgaHash{'gameTime'} = '';
	$pgaHash{'homeTeam'} = $Winnings;
	$pgaHash{'homeScore'} = "     $Score";
	$pgaHash{'awayTeam'} = "$Position   $Player";
	# optional team logos...
        $pgaHash{'gameLogoURL'} = "http://mdmplugins.googlecode.com/svn/trunk/images/$Player.jpg";

	Plugins::SuperDateTime::Plugin::addCustomSportScore(\%pgaHash);
	# Create macros for use by Custom Clock
	Plugins::SuperDateTime::Plugin::addMacro("$XPGAPlayer", "$Player");
	Plugins::SuperDateTime::Plugin::addMacro("$XPGAPosition", "$Position");
	#Plugins::SuperDateTime::Plugin::addMacro("$XPGAWinnings", "$Winnings");
	#Plugins::SuperDateTime::Plugin::addMacro("$XPGAScore", "$Score");
	#Plugins::SuperDateTime::Plugin::addMacro("$XPGAThru", "$Thru");
	#Plugins::SuperDateTime::Plugin::addMacro("$XPGATournamentName", "$TournamentName");
}

sub sendToJiveDuring {
        my %pgaHash;
        my $zero_num;
        $zero_num = sprintf("%03d", $PlayerTotal);  # Needed to pad with leading zeros to sort right
        
        $pgaHash{'sport'} = $TournamentName;
	$pgaHash{'gameID'} = $zero_num;
	#$pgaHash{'gameTime'} = $Player;
	$pgaHash{'homeTeam'} = $Score;
	$pgaHash{'homeScore'} = "     ($Thru)";
	$pgaHash{'awayTeam'} = "$Position   $Player";
	# optional team logos...
        $pgaHash{'gameLogoURL'} = "http://mdmplugins.googlecode.com/svn/trunk/images/$Player.jpg";

	Plugins::SuperDateTime::Plugin::addCustomSportScore(\%pgaHash);
}

sub getPGAScores {
	my $timerObj = shift; #Should be undef, unless called from a timer
	my $client = shift;
	my $refreshItem = shift;
	
	my $url = 'http://sports.espn.go.com/golf/leaderboard';
	#my $url = 'http://sports.espn.go.com/golf/leaderboard?tour=champions';
	my $http = Slim::Networking::SimpleAsyncHTTP->new(\&gotPGAScores,
			\&Plugins::SuperDateTime::Plugin::gotErrorViaHTTP,
			{client => $client,
			 caller => 'getPGAScores',
			 callerProc => \&getPGAScores,
			 refreshItem => $refreshItem});
		
	#$log->info("aync request: $url");
	$http->get($url);
}

sub gotPGAScores {
	my $http = shift;
	

        my $CheckForTies = '';
        my $TopPlayers = $prefs->get('pref_topgolfers');
        my $PlayerLimit = $prefs->get('pref_maxgolfers');
        my $PlayerTracker1 = $prefs->get('pref_tracker1');
        my $PlayerTracker2 = $prefs->get('pref_tracker2');
        my $ShowPGA = $prefs->get('pref_showpga');
        my $Round1Done = '';
        my $TourneyDay = 'Y';
        my $TourneyLength = '';
        my $DisplayLength = '';
        my $TourneyStatusLength = '';

	my $params = $http->params();
	my $client = $params->{'client'};
	my $refreshItem = $params->{'refreshItem'};
	
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        my $DayOfWeek = $wday;
        
        $PlayerTotal = '0';
        Plugins::SuperDateTime::Plugin::delCustomSport($TournamentName);

	#$log->info("Day of week is : $DayOfWeek");
	
        if (($DayOfWeek eq '1') || ($DayOfWeek eq '2') || ($DayOfWeek eq '3') || ($ShowPGA ne '1')) {    # Nothing on Mon, Tues and Weds
                $TourneyDay = 'N';
        }

	#$log->info("got " . $http->url());

	my $content = $http->content();
    
	#my @ary=split /Leaderboards: PGA/,$content; #break large string into array
        #my @defchamp=split /Leaderboards: PGA/,$content;
        #my @Status=split /Leaderboards: PGA/,$content;

 	my @ary=split /Tours:/,$content; #break large string into array
        my @defchamp=split /Tours:/,$content;
        my @Status=split /Tours:/,$content;

       	for (@defchamp) {
                if (/Def. Champ:<\/strong> (.+?)\s-\s/s) {
                        $DefendingChamp = $1;
                        #$log->info("$DefendingChamp");
                }
        }
        
        for (@ary) {
                #.*Tournament Info.*colspan="2">(.+?)<\/td>.+?center>.+?\s.?-\s(.+?)<\/td>      champions tour
                #.*Tournament Info.*colspan="2">(.+?)\s\s.+?center>.+?\s\s+(-?.+?)<\/td>
                if (/tablehead".*?<tr class="stathead.*?align=center>(.+?)\s*-\s(.+?)<\/td>/s) {
                        $TournamentName = $1;
                        $TourneyStatus = $2;
                        $TourneyStatusLength = length($TourneyStatus);
                        $TourneyLength = length($TournamentName);
                        #$log->info("$TournamentName");
                        #$log->info("$TournamentStatus");
                        #$log->info("$DefendingChamp");
                        #$log->info("$PlayerTracker1");
                        #$log->info("$PlayerTracker2");
                        #$log->info("$TopPlayers");
                        #$log->info("$PlayerLimit");
                        #$log->info("$TourneyStatusLength");
                        #$log->info("$TourneyLength");


                        my @players=split /<tr class=/;
                        if ($TourneyDay eq 'Y' or $TourneyStatus ne 'Final') {
                                for (@players) {
                                        # During Tournament
                                        #if (/center>(.+?)<\/TD>.+?"namelink">(.+?)<\/SPAN>.+?center>(.+?)<\/TD>.+?center>(.+?)<\/TD>.+?<\/TD><TD>(.+?)<\/TD>/s) {
                                        #if (/center">(.+?)<\/td>.+?player_id.+?>(.+?)<\/a>.+?center">(.+?)<\/td>.+?center">(.+?)<\/td><td>(.+?)<\/td>/s {
                                        #if (/><\/td><td align="center">(.+?)<\/td>.+?player_id.+?>(.+?)<\/a>.+?center">(.+?)<\/td>.+?center">(.+?)<\/td>.+?<td>(.+?)<\/td>/s) {
                                        if (/center".+?>(.+?)<\/td>.+?player_id.+?>(.+?)<\/a>.+?center" >(.+?)<\/td>.+?thru".+?>(.+?)<\/td/s) {
			                     $Position = $1;
			                     $Player = $2;
			                     $Score = $3;
			                     $Thru = $4;
			                     #$Round1Done = $5;
                                             $CheckForTies = substr($Position,0,1);
                                             #$log->info("$Player");
                                             #$log->info("$Thru");
                                             #$log->info("$Round1Done");
                                             #$log->info("$CheckForTies");
                                             $PlayerTracker1 =~ s/'/&#39;/g;  # apostrophe logic
                                             $PlayerTracker2 =~ s/'/&#39;/g;  # apostrophe logic
                                             $Player =~ s/&#39;/'/g;          # apostrophe logic
                                             $Position =~ s/&nbsp;/NA/g;
                                             
                                             if ($TourneyLength < 100) {
                                                Plugins::SuperDateTime::Plugin::addCustomSportLogo($TournamentName, "http://mdmplugins.googlecode.com/svn/trunk/PGA_TourLogo.gif");
                                             }
                                     
                                             if ($Player eq $DefendingChamp) {
                                                $Player =~ s/$Player/$Player^/g;
                                             }
                                     
                                             if ((substr($Thru,0,1) eq '<') || ($Thru eq '')) {      # WD or DQ?  We'll just call them finished.
                                                $Thru = 'F';
                                             }
                                             
                                             $DisplayLength = length($Position) + length($Player) + length($Score) + length($Thru);
                                             if (($Position <= $TopPlayers) && ($CheckForTies ne 'T') && ($PlayerTotal < $PlayerLimit) && ($TourneyLength < 100) && ($Position ne 'NA')) {
                                                $PlayerTotal++;
                                                if ($PlayerTotal eq '1') {
                                                   if ($TourneyLength > '23') {
                                                        Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Leaderboard - $TourneyStatus", "$TournamentName", 'L');
                                                        sendToJiveDuring;
                                                   } else {
                                                        Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Leaderboard - $TourneyStatus", "$TournamentName", 5);
                                                        sendToJiveDuring;
                                                   }
                                                }
                                                if ($DisplayLength > '23') {
                                                     Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Leaderboard - $TourneyStatus", "$Position   $Player   $Score   ($Thru)", 'L');
                                                     sendToJiveDuring;
                                                } else {
                                                     Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Leaderboard - $TourneyStatus", "$Position   $Player   $Score   ($Thru)", 5);
                                                     sendToJiveDuring;
                                                }
                                             } elsif ((substr($Position,1,3) <= $TopPlayers) && ($CheckForTies eq 'T') && ($PlayerTotal < $PlayerLimit)) {
                                                $PlayerTotal++;
                                                if ($PlayerTotal eq '1') {
                                                   if ($TourneyLength > '23') {
                                                        Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Leaderboard - $TourneyStatus", "$TournamentName", 'L');
                                                        sendToJiveDuring;
                                                   } else {
                                                        Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Leaderboard - $TourneyStatus", "$TournamentName", 5);
                                                        sendToJiveDuring;
                                                   }
                                                }
                                                if ($DisplayLength > '23') {
                                                     Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Leaderboard - $TourneyStatus", "$Position   $Player   $Score   ($Thru)", 'L');
                                                     sendToJiveDuring;
                                                } else {
                                                     Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Leaderboard - $TourneyStatus", "$Position   $Player   $Score   ($Thru)", 5);
                                                     sendToJiveDuring;
                                                }
                                             } elsif (((/$PlayerTracker1/i) || (/$PlayerTracker2/i)) && ($TourneyLength < 100)) {
                                                $PlayerTotal++;
                                                if ($DisplayLength > '23') {
                                                     Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Leaderboard - $TourneyStatus", "$Position   $Player   $Score   ($Thru)", 'L');
                                                     Plugins::SuperDateTime::Plugin::addMacro("%XPlayer", "$Player");
                                                     sendToJiveDuring;
                                                } else {
                                                     Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Leaderboard - $TourneyStatus", "$Position   $Player   $Score   ($Thru)", 5);
                                                     sendToJiveDuring;
                                                }
                                        }
                                        #  Tourney complete
			                #} elsif (/center>(.+?)<\/TD>.+?"namelink">(.+?)<\/SPAN>.+?center>(.+?)<\/TD>.+?center>.+?<TD>(.+?)<\/TD>/s) {
			                } elsif (/center".+?>(.+?)<\/td>.+?player_id.+?>(.+?)<\/a>.+?center".+?>(.+?)<\/td>.+?earnings.+?>(.+?)<\/td>/s) {
			                        $Position = $1;
			                        $Player = $2;
			                        $Score = $3;
			                        $Winnings = $4;
                                                $CheckForTies = substr($Position,0,1);

                                                $PlayerTracker1 =~ s/'/&#39;/g;  # apostrophe logic
                                                $PlayerTracker2 =~ s/'/&#39;/g;  # apostrophe logic
                                                $Player =~ s/&#39;/'/g;          # apostrophe logic
                                                $Position =~ s/&nbsp;/NA/g;

                                                if ($TourneyLength < 100) {
                                                        Plugins::SuperDateTime::Plugin::addCustomSportLogo($TournamentName, "http://mdmplugins.googlecode.com/svn/trunk/PGA_TourLogo.gif");
                                                }
                                                
                                                if ($Player eq $DefendingChamp) {
                                                        $Player =~ s/$Player/$Player^/g;
                                                }

                                                # Check to see if it will fit on one line or need to scroll
                                                $DisplayLength = length($Position) + length($Player) + length($Score) + length($Winnings);
                                                
                                                if (($Position <= $TopPlayers) && ($CheckForTies ne 'T') && ($PlayerTotal < $PlayerLimit) && ($Position ne 'NA')){
                                                   $PlayerTotal++;
                                                   if ($PlayerTotal eq '1') {    # First time through display tournament name
                                                        if ($TourneyLength > '23') {
                                                                Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Tour Results - $TourneyStatus", "$TournamentName", 'L');
                                                                sendToJiveFinal;
                                                        } else {
                                                                Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Tour Results - $TourneyStatus", "$TournamentName", 5);
                                                                sendToJiveFinal;
                                                        }
                                                   }
                                                   if ($DisplayLength > '23') {
                                                        Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Tour Results - $TourneyStatus", "$Position   $Player   $Score  $Winnings", 'L');
                                                        sendToJiveFinal;
                                                   } else {
                                                        Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Tour Results - $TourneyStatus", "$Position   $Player   $Score  $Winnings", 5);
                                                        sendToJiveFinal;

                                                   }
                                                } elsif ((substr($Position,1,2) <= $TopPlayers) && ($CheckForTies eq 'T') && ($PlayerTotal < $PlayerLimit)) {
                                                   $PlayerTotal++;
                                                   if ($PlayerTotal eq '1') {
                                                        if ($TourneyLength > '23') {
                                                                Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Tour Results - $TourneyStatus", "$TournamentName", 'L');
                                                                sendToJiveFinal;
                                                        } else {
                                                                Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Tour Results - $TourneyStatus", "$TournamentName", 5);
                                                                sendToJiveFinal;
                                                        }
                                                   }
                                                   if ($DisplayLength > '23') {
                                                        Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Tour Results - $TourneyStatus", "$Position   $Player   $Score  $Winnings", 'L');
                                                        sendToJiveFinal;
                                                   } else {
                                                        Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Tour Results - $TourneyStatus", "$Position   $Player   $Score  $Winnings", 5);
                                                        sendToJiveFinal;
                                                   }
                                                } elsif (((/$PlayerTracker1/i) || (/$PlayerTracker2/i)) && ($TourneyLength < 100)) {
                                                        $PlayerTotal++;
                                                        if ($DisplayLength > '23') {
                                                                Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Tour Results - $TourneyStatus", "$Position   $Player   $Score  $Winnings", 'L');
                                                                sendToJiveFinal;
                                                        } else {
                                                                Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Scores", "PGA Tour Results - $TourneyStatus", "$Position   $Player   $Score  $Winnings", 5);
                                                                sendToJiveFinal;
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }
	Plugins::SuperDateTime::Plugin::refreshData(undef, $client, $refreshItem);
}

sub getChampionScores {
	my $timerObj = shift; #Should be undef, unless called from a timer
	my $client = shift;
	my $refreshItem = shift;

 	my $url = 'http://sports.espn.go.com/golf/leaderboard?tour=champions';
	my $http = Slim::Networking::SimpleAsyncHTTP->new(\&gotChampionScores,
			\&Plugins::SuperDateTime::Plugin::gotErrorViaHTTP,
			{client => $client,
			 caller => 'getChampionScores',
			 callerProc => \&getChampionScores,
			 refreshItem => $refreshItem});

	#$log->info("aync request: $url");
	$http->get($url);
}

sub gotChampionScores {
	my $http = shift;

        my $TournamentName = '';
        my $DefendingChamp = '';
        my $TourneyStatus = '';
        my $Player = '';
        my $Position = '';
        my $Score = '';
        my $Thru = '';
        my $CheckForTies = '';
        my $ChampTopPlayers = $prefs->get('pref_champtopgolfers');
        my $ChampPlayerLimit = $prefs->get('pref_champmaxgolfers');
        my $ChampPlayerTracker1 = $prefs->get('pref_champtracker1');
        my $ChampPlayerTracker2 = $prefs->get('pref_champtracker2');
        my $ShowChamp = $prefs->get('pref_showchamp');
        my $Round1Done = '';
        my $ChampPlayerTotal = '';
        my $Winnings = '';
        my $TourneyDay = 'Y';
        my $TourneyLength = '';
        my $DisplayLength = '';
        my $TourneyStatusLength = '';

	my $params = $http->params();
	my $client = $params->{'client'};
	my $refreshItem = $params->{'refreshItem'};

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        my $DayOfWeek = $wday;

	#$log->info("Day of week is : $DayOfWeek");
	
	#$log->info("ShowChamp is : $ShowChamp");

        if (($DayOfWeek eq '1') || ($DayOfWeek eq '2') || ($DayOfWeek eq '3') || ($ShowChamp ne '1')) {    # Nothing on Mon, Tues and Weds
                $TourneyDay = 'N';
        }

	#$log->info("got " . $http->url());

	my $content = $http->content();

	#my @ary=split /Leaderboards: PGA/,$content; #break large string into array
        #my @defchamp=split /Leaderboards: PGA/,$content;
        #my @Status=split /Leaderboards: PGA/,$content;

 	my @ary=split /Tours:/,$content; #break large string into array
        my @defchamp=split /Tours:/,$content;
        my @Status=split /Tours:/,$content;

       	for (@defchamp) {
                if (/Def. Champ:<\/strong> (.+?) -.+?<br/s) {
                        $DefendingChamp = $1;
                        #$log->info("$DefendingChamp");
                }
        }

        if ($TourneyDay eq 'Y') {
                for (@ary) {
                        if (/tablehead".+?<tr class="stathead.*?align=center>(.+?)\s- (.+?)<\/td>/s) {
                                $TournamentName = $1;
                                $TourneyStatus = $2;
                                $TourneyStatusLength = length($TourneyStatus);
                                $TourneyLength = length($TournamentName);
                                #$log->info("$TournamentName");
                                #$log->info("$DefendingChamp");
                                #$log->info("$ChampPlayerTracker1");
                                #$log->info("$ChampPlayerTracker2");
                                #$log->info("$ChampTopPlayers");
                                #$log->info("$ChampPlayerLimit");

                                my @players=split /<tr class=/;
                                for (@players) {
                                        # During Tournament
                                        if (/center">(.+?)<\/td>.+?player_id.+?>(.+?)<\/a>.+?center">(.+?)<\/td>.+?center">(.+?)<\/td>.+?<td>(.+?)<\/td>/s) {
			                     $Position = $1;
			                     $Player = $2;
			                     $Score = $3;
			                     $Thru = $4;
			                     $Round1Done = $5;
                                             $CheckForTies = substr($Position,0,1);
                                             #$log->info("$Player");
                                             #$log->info("$Thru");
                                             #$log->info("$Round1Done");
                                             #$log->info("$CheckForTies");
                                             $ChampPlayerTracker1 =~ s/'/&#39;/g;  # apostrophe logic
                                             $ChampPlayerTracker2 =~ s/'/&#39;/g;  # apostrophe logic
                                             $Player =~ s/&#39;/'/g;          # apostrophe logic

                                             if ($Player eq $DefendingChamp) {
                                                $Player =~ s/$Player/$Player^/g;
                                             }

                                             if ((substr($Thru,0,1) eq '<') || ($Thru eq '')) {      # WD or DQ?  We'll just call them finished.
                                                $Thru = 'F';
                                             }

                                             $DisplayLength = length($Position) + length($Player) + length($Score) + length($Winnings);
                                             if (($Position <= $ChampTopPlayers) && ($CheckForTies ne 'T') && ($ChampPlayerTotal < $ChampPlayerLimit)) {
                                                $ChampPlayerTotal++;
                                                if ($ChampPlayerTotal eq '1') {
                                                   Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Leaderboard", "Champions Leaderboard - $TourneyStatus", "$TournamentName", 5);
                                                }
                                                Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Leaderboard", "Champions Leaderboard - $TourneyStatus", "$Position   $Player   $Score   ($Thru)", 5);
                                             } elsif ((substr($Position,1,3) <= $ChampTopPlayers) && ($CheckForTies eq 'T') && ($ChampPlayerTotal < $ChampPlayerLimit)) {
                                                $ChampPlayerTotal++;
                                                if ($ChampPlayerTotal eq '1') {
                                                   Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Leaderboard", "Champions Leaderboard - $TourneyStatus", "$TournamentName", 5);
                                                }
                                                Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Leaderboard", "Champions Leaderboard - $TourneyStatus", "$Position   $Player   $Score   ($Thru)", 5);
                                             } elsif ((/$ChampPlayerTracker1/i) || (/$ChampPlayerTracker2/i)) {
                                                Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Leaderboard", "Champions Leaderboard - $TourneyStatus", "$Position   $Player   $Score   ($Thru)", 5);
                                             }
                                        #  Tourney complete
			                #} elsif (/center>(.+?)<\/TD>.+?"namelink">(.+?)<\/SPAN>.+?center>(.+?)<\/TD>.+?center>.+?<TD>(.+?)<\/TD>/s) {
			                } elsif (/center">(.+?)<\/td>.+?player_id.+?>(.+?)<\/a>.+?center">(.+?)<\/td>.+?center">.+?<td>(.+?)<\/td>/s) {
			                        $Position = $1;
			                        $Player = $2;
			                        $Score = $3;
			                        $Winnings = $4;
                                                $CheckForTies = substr($Position,0,1);

                                                $ChampPlayerTracker1 =~ s/'/&#39;/g;  # apostrophe logic
                                                $ChampPlayerTracker2 =~ s/'/&#39;/g;  # apostrophe logic
                                                $Player =~ s/&#39;/'/g;          # apostrophe logic

                                                if ($Player eq $DefendingChamp) {
                                                        $Player =~ s/$Player/$Player^/g;
                                                }

                                                $DisplayLength = length($Position) + length($Player) + length($Score) + length($Winnings);
                                                if (($Position <= $ChampTopPlayers) && ($CheckForTies ne 'T') && ($ChampPlayerTotal < $ChampPlayerLimit)){
                                                  $ChampPlayerTotal++;
                                                  if ($ChampPlayerTotal eq '1') {
                                                    Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Leaderboard", "Champions Results - $TourneyStatus", "$TournamentName", 5);
                                                  }
                                                  Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Leaderboard", "Champions Results - $TourneyStatus", "$Position   $Player   $Score  $Winnings", 5);
                                                } elsif ((substr($Position,1,2) <= $ChampTopPlayers) && ($CheckForTies eq 'T') && ($ChampPlayerTotal < $ChampPlayerLimit)) {
                                                  $ChampPlayerTotal++;
                                                  if ($ChampPlayerTotal eq '1') {
                                                    Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Leaderboard", "Champions Results - $TourneyStatus", "$TournamentName", 5);
                                                  }
                                                  Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Leaderboard", "Champions Results - $TourneyStatus", "$Position   $Player   $Score  $Winnings", 5);
                                                } elsif ((/$ChampPlayerTracker1/i) || (/$ChampPlayerTracker2/i)) {
                                                        Plugins::SuperDateTime::Plugin::addDisplayItem("PGA Leaderboard", "Champions Results - $TourneyStatus", "$Position   $Player   $Score  $Winnings", 5);
                                                }
                                        }
                                }
                        }
                }
        }
	Plugins::SuperDateTime::Plugin::refreshData(undef, $client, $refreshItem);
}

1;

__END__
