#!/usr/bin/perl
#
# Fix permissions.
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

use UBOS::Utils;

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $appsDir     = "$dir/apps";

my $apacheUname = $config->getResolve( 'apache2.uname' );
my $apacheGname = $config->getResolve( 'apache2.gname' );

if( 'deploy' eq $operation ) {
    UBOS::Utils::myexec( "chown -R $apacheUname:$apacheGname '$appsDir' '$dir/index.html'" );
}

1;
