#!/usr/bin/perl
#
# Configure fulltextsearch
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $dir = $config->getResolve( 'appconfig.apache2.dir' );

my $cmdPrefix = "cd $dir; sudo -u http php";
$cmdPrefix .= ' -d memory_limit=512M';
$cmdPrefix .= ' occ';

my $out;

if( 'install' eq $operation || 'upgrade' eq $operation ) {

    my $json = <<'JSON';
{
    "search_platform": "OCA\\FullTextSearch_ElasticSearch\\Platform\\ElasticSearchPlatform"
}
JSON

    if( UBOS::Utils::myexec( "$cmdPrefix fulltextsearch:configure '$json'", undef, \$out, \$out ) != 0 ) {
        error( "Configuring Nextcloud app fulltextsearch failed:", $out );
    }
}

1;
