#!/usr/bin/perl
#
# Configure Nextcloud elasticsearch
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $appConfigId = $config->getResolve( 'appconfig.appconfigid' );

# not resolvable with ${...} in upgrader
my $port = UBOS::ResourceManager::findProvisionedPortFor(
        'tcp',
        $appConfigId,
        'nextcloud-fulltextsearch-elasticsearch',
        'main' );

my $cmdPrefix = "cd $dir; sudo -u http php";
$cmdPrefix .= ' -d memory_limit=512M';
$cmdPrefix .= ' occ';

my $out;

if( 'install' eq $operation || 'upgrade' eq $operation ) {

    my $json = <<JSON;
{
    "elastic_host": "http:\/\/localhost:${port}\/",
    "elastic_index": "nextcloud-$appConfigId"
}
JSON

    if( UBOS::Utils::myexec( "$cmdPrefix fulltextsearch_elasticsearch:configure '$json'", undef, \$out, \$out ) != 0 ) {
        error( "Configuring Nextcloud app fulltextsearch_elasticsearch failed:", $out );
    }
}

1;
