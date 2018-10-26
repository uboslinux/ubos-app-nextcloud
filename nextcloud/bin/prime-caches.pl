#!/usr/bin/perl
#
# Prime the caches so Nextcloud comes up faster
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

use UBOS::Logging;
use UBOS::Utils;

if(    'install' eq $operation
    || 'upgrade' eq $operation )
{
    my $proto    = $config->getResolve( 'site.protocol' );
    my $hostname = $config->getResolve( 'site.hostname' );
    my $context  = $config->getResolve( 'appconfig.context' );
    my $url      = "$proto$hostname$context";

    my $out;
    if( UBOS::Utils::myexec( "curl $url/", undef, \$out, \$out )) {
        error( 'curl prime-caches (1) failed:', $out );

    } elsif( UBOS::Utils::myexec( "curl -L $url/apps/files/", undef, \$out, \$out )) {
        error( 'curl prime-caches (2) failed:', $out );
    }
}

1;
