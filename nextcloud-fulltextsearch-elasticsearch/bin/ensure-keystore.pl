#!/usr/bin/perl
#
# If the keystore is empty or does not exist, we generate it.
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $appConfigId = $config->getResolve( 'appconfig.appconfigid' );

if( 'deploy' eq $operation || 'upgrade' eq $operation ) {

    my $keyStoreFile = "/etc/elasticsearch/$appConfigId/elasticsearch.keystore";
    my $keyStoreData = undef;

    if( -e $keyStoreFile ) {
        $keyStoreData = UBOS::Utils::slurpFile( $keyStoreFile );
        unless( $keyStoreData ) {
            # Delete
            unless( UBOS::Utils::deleteFile( $keyStoreFile )) {
                error( 'Failed to delete: ', $keyStoreFile );
            }
        }
    }
    unless( $keyStoreData ) {
        if( UBOS::Utils::myexec( "systemctl start elasticsearch-keystore\@$appConfigId.service" )) {
            error( "Failed to start elasticsearch-keystore\@$appConfigId.service" );
        }
    }
}

1;
