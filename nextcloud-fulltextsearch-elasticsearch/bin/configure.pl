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

##

    my $appName = 'fulltextsearch';
    my $json    = <<'JSON';
{
    "search_platform": "OCA\\FullTextSearch_ElasticSearch\\Platform\\ElasticSearchPlatform"
}
JSON

    if( UBOS::Utils::myexec( "$cmdPrefix $appName:configure '$json'", undef, \$out, \$out ) != 0 ) {
        error( "Configuring Nextcloud app $appName failed:", $out );
    }

##

    $appName = 'files_fulltextsearch';
    $json    = <<JSON;
{
    "files_local": "1",
    "files_external": "0",
    "files_group_folders": "1",
    "files_size": "20",
    "files_pdf": "1",
    "files_office": "1"
}
JSON
    # local: yes
    # external: index path only
    # group folders: yes
    # size: up to 20MB
    # extract PDF and Office files

    if( UBOS::Utils::myexec( "$cmdPrefix $appName:configure '$json'", undef, \$out, \$out ) != 0 ) {
        error( "Configuring Nextcloud app $appName failed:", $out );
    }

##

    $appName = 'fulltextsearch_elasticsearch';
    $json    = <<JSON;
{
    "elastic_host": "http:\/\/localhost:${port}\/",
    "elastic_index": "nextcloud"
}
JSON

    if( UBOS::Utils::myexec( "$cmdPrefix $appName:configure '$json'", undef, \$out, \$out ) != 0 ) {
        error( "Configuring Nextcloud app $appName failed:", $out );
    }
}

1;
