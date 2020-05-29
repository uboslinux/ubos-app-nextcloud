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
        # Don't use elasticsearch-keystore@.service -- race condition
        my $cmd  = 'sudo -u elasticsearch';
        $cmd    .= " ES_PATH_CONF=/etc/elasticsearch/$appConfigId";
        $cmd    .= ' /usr/share/elasticsearch/bin/elasticsearch-keystore create';

        my $out;
        if( UBOS::Utils::myexec( $cmd, undef, \$out, \$out )) {
            error( 'Failed to create elasticsearch keystore for', $appConfigId, $out );
        }
    }
}

1;
