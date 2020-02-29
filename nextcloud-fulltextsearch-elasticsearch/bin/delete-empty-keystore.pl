#!/usr/bin/perl
#
# This is a hack. The elasticsearch systemd service will automatically
# generate a keystore if the keystore file does not exist. However, we
# also want to back up that file. So we auto-generate it empty, and if
# it is empty just before starting the systemd.service, we delete it.
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $appConfigId = $config->getResolve( 'appconfig.appconfigid' );

if( 'deploy' eq $operation || 'upgrade' eq $operation ) {

    my $keyStoreFile = "/etc/elasticsearch/$appConfigId/elasticsearch.keystore";
    my $keyStoreData = UBOS::Utils::slurpFile( $keyStoreFile );
    if( defined( $keyStoreData ) && !$keyStoreData ) {
        unless( UBOS::Utils::deleteFile( $keyStoreFile )) {
            error( 'Failed to delete: ', $keyStoreFile );
        }
    }
}


1;
