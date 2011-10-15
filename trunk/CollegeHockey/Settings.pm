package Slim::Plugin::CollegeHockey::Settings;

# SqueezeCenter Copyright 2001-2007 Logitech.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.

use strict;
use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;

my $prefs = preferences('plugin.collegehockey');

sub name {
	return Slim::Web::HTTP::CSRF->protectName('PLUGIN_SCREENSAVER_COLLEGEHOCKEY');
}

sub page {
	return Slim::Web::HTTP::CSRF->protectURI('plugins/CollegeHockey/settings/basic.html');
}

sub prefs {
	return ($prefs, qw(pref_team1 pref_team2));
}


1;

__END__
