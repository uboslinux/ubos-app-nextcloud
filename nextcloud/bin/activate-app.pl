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

my $cmdPrefix = "cd $dir; sudo -u http php";
$cmdPrefix .= ' -d memory_limit=512M';
$cmdPrefix .= ' occ';

my $out;

if( 'install' eq $operation || 'upgrade' eq $operation ) {

    if( UBOS::Utils::myexec( "$cmdPrefix app:enable $appName", undef, \$out, \$out ) != 0 ) {
        if( $out =~ m!not compatible with this version! ) {
            if( UBOS::Logging::isTraceActive() ) {
                warning( "Not automatically activating Nextcloud app $appName because it has not been tested with this version of Nextcloud:", $out );
            } else {
                warning( "Not automatically activating Nextcloud app $appName because it has not been tested with this version of Nextcloud" );
            }
        } else {
            error( "Activating Nextcloud app $appName failed:", $out );
        }
    }

} else {
    if( UBOS::Utils::myexec( "$cmdPrefix app:disable $appName", undef, \$out, \$out ) != 0 ) {
        error( "Activating Nextcloud app $appName failed:", $out );
    }
}


1;
