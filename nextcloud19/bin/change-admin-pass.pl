#!/usr/bin/perl
#
# Change admin password.
#
# Copyright (C) 2019 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

use UBOS::Logging;
use UBOS::Utils;

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $apacheUname = $config->getResolve( 'apache2.uname' );
my $adminlogin  = $config->getResolve( 'site.admin.userid' );
my $adminpass   = $config->getResolve( 'site.admin.credential' );
my $ret         = 1;

if( 'upgrade' eq $operation ) {
# Run occ upgrade
    my $cmd = "cd '$dir';";
    $cmd .= "sudo -u '$apacheUname'";
    $cmd .= ' OC_PASS="' . $adminpass . '"';
    $cmd .= ' php';
    $cmd .= ' -d always_populate_raw_post_data=-1';
    $cmd .= ' -d memory_limit=512M';
    $cmd .= ' occ';
    $cmd .= ' user:resetpassword';
    $cmd .= ' "' . $adminlogin . '"';
    $cmd .= ' --password-from-env';

    my $out;
    my $err;
    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$err )) {
        error( "$cmd failed:\n$out\n$err" );
        $ret = 0;
    }
}

1;
