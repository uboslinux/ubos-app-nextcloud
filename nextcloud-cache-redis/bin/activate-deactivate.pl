#!/usr/bin/perl
#
# Activate and deactivate Redis caching for Nextcloud. Only invoke from ubos-manifest.json.
#
# Copyright (C) 2018 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $apacheUname = $config->getResolve( 'apache2.uname' );
my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $appconfigid = $config->getResolve( 'appconfig.appconfigid' );
my $redispass   = $config->getResolve( 'installable.customizationpoints.redispass.value' );

my $cmdPrefix = "cd '$dir';";
$cmdPrefix .= "sudo -u '$apacheUname' php";
$cmdPrefix .= ' -d always_populate_raw_post_data=-1';
$cmdPrefix .= ' occ';


my $out;
if( 'install' eq $operation || 'update' eq $operation ) {
    # Set the parameters first, then that we use Redis, otherwise failure
    for my $cmd (
            'config:system:set redis host --value=/var/run/nextcloud-cache-redis/' . $appconfigid . '.sock',
            'config:system:set redis port --value=0',
            'config:system:set redis dbindex --value=0',
            'config:system:set redis password --value=' . $redispass,
            'config:system:set redis timeout --value=1.5',
            'config:system:set memcache.local --value=\\\\OC\\\\Memcache\\\\Redis' )
    {
        if( UBOS::Utils::myexec( "$cmdPrefix $cmd", undef, \$out, \$out )) {
            error( "Nextcloud command failed:\n$cmd\n$out" );
        }
    }

} else {
    if( UBOS::Utils::myexec( "$cmdPrefix config:system:delete memcache.local", undef, \$out, \$out ) != 0 ) {
        error( "Dectivating Nextcloud Redis cache failed:", $out );
    }
    if( UBOS::Utils::myexec( "$cmdPrefix config:system:delete redis", undef, \$out, \$out ) != 0 ) {
        error( "Removing Nextcloud Redis cache configuration failed:", $out );
    }
}

1;
