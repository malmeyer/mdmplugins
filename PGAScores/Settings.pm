package Slim::Plugin::PGAScores::Settings;

# SqueezeCenter Copyright 2001-2007 Logitech.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
# version 2.

use strict;
use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;

my $prefs = preferences('plugin.pgascores');

sub name {
	return Slim::Web::HTTP::protectName('PLUGIN_SCREENSAVER_PGASCORES');
}

sub page {
	return Slim::Web::HTTP::protectURI('plugins/PGAScores/settings/basic.html');
}

sub prefs {
	return ($prefs, qw(pref_tracker1 pref_tracker2 pref_topgolfers pref_maxgolfers
                pref_champtracker1 pref_champtracker2 pref_champtopgolfers pref_champmaxgolfers
                pref_showpga pref_showchamp ));
}

1;

__END__
