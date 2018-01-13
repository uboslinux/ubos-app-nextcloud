#!/usr/bin/perl
#
# Activate a Nextcloud app. Only invoke from ubos-manifest.json.
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $appName = $config->getResolve( 'installable.accessoryinfo.accessoryid' );
my $dir     = $config->getResolve( 'appconfig.apache2.dir' );

my $cmdPrefix = "cd $dir; sudo -u http php occ";
my $out;

if( 'install' eq $operation ) {

    if( UBOS::Utils::myexec( "$cmdPrefix app:enable $appName", undef, \$out, \$out ) != 0 ) {
        error( "Activating Nextcloud app $appName failed:", $out );
    }

} else {
    if( UBOS::Utils::myexec( "$cmdPrefix app:disable $appName", undef, \$out, \$out ) != 0 ) {
        error( "Activating Nextcloud app $appName failed:", $out );
    }
}


1;
