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

my $occCmdPrefix = "$cmdPrefix occ";

my $out;

if( 'install' eq $operation ) {
    if( UBOS::Utils::myexec( "$occCmdPrefix config:system:set memcache.local --value '\\OC\\Memcache\\Redis'", undef, \$out, \$out ) != 0 ) {
        error( "Activating Nextcloud Redis cache failed:", $out );
    }
    if( UBOS::Utils::myexec( $cmdPrefix, <<PHP, \$out, \$out ) != 0 ) {
<?php

require_once 'lib/base.php';

\$config = \\OC::\$server->getConfig()->getSystemConfig();

\$config->setValues( [
    'redis' => [
        'host' => '/run/nextcloud-cache-redis/$appconfigid.sock',
        'port' => 0,
        'dbindex' => 0,
        'password' => '$redispass',
        'timeout' => 1.5
    ]] );
PHP
        error( "Adding Nextcloud Redis configuration failed:", $out );
    }

    # apparently occ cannot currently insert hierarchical values, so we bypass it

} else {
    if( UBOS::Utils::myexec( "$occCmdPrefix config:system:delete memcache.local", undef, \$out, \$out ) != 0 ) {
        error( "Dectivating Nextcloud Redis cache failed:", $out );
    }
    if( UBOS::Utils::myexec( "$occCmdPrefix config:system:delete redis", undef, \$out, \$out ) != 0 ) {
        error( "Removing Nextcloud Redis cache configuration failed:", $out );
    }
}

1;
