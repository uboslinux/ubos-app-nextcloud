#!/usr/bin/perl
#
# Run the indexer
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use Getopt::Long qw( GetOptionsFromArray );
use UBOS::Host;
use UBOS::Logging;
use UBOS::Utils;


my $verbose           = 0;
my $logConfigFile     = undef;
my $debug             = undef;

my $parseOk = GetOptionsFromArray(
        \@ARGV,
        'verbose+'    => \$verbose,
        'logConfig=s' => \$logConfigFile,
        'debug'       => \$debug );

UBOS::Logging::initialize( 'nextcloud-fulltextsearch-elasticsearch', 'index.pl', $verbose, $logConfigFile, $debug );

if( @ARGV != 2 ) {
    fatal( 'Synopsis: { start | stop } <appconfigid>' );
}

my $command     = $ARGV[0];
my $appConfigId = $ARGV[1];

my $appConfig = UBOS::Host::findAppConfigurationById( $appConfigId );
unless( $appConfig ) {
    fatal( 'Failed to find AppConfiguration', $appConfigId );
}
my $dir       = $appConfig->vars()->getResolve( 'appconfig.apache2.dir' );

my $cmdPrefix = "cd $dir; sudo -u http php";
$cmdPrefix .= ' -d memory_limit=512M';
$cmdPrefix .= ' occ';

info( 'Command:', $command );

if( 'start' eq $command ) {
    my $indexedFlag = "/ubos/lib/nextcloud-fulltextsearch-elasticsearch/$appConfigId-state/indexed";
    unless( -e $indexedFlag ) {
        info( 'running fulltextsearch:index' );
        if( UBOS::Utils::myexec( "$cmdPrefix fulltextsearch:index -q -r" )) {
            error( "$cmdPrefix fulltextsearch:index failed" );
            exit( 1 );
        }

        UBOS::Utils::saveFile( $indexedFlag, UBOS::Utils::time2string( UBOS::Utils::now()));
    }
    info( 'running fulltextsearch:live' );
    if( UBOS::Utils::myexec( "$cmdPrefix fulltextsearch:live -q -r" )) {
        error( "$cmdPrefix fulltextsearch:live failed" );
        exit( 1 );
    }

} elsif( 'stop' eq $command ) {
    info( 'running fulltextsearch:stop' );
    if( UBOS::Utils::myexec( "$cmdPrefix fulltextsearch:stop" )) {
        error( "$cmdPrefix fulltextsearch:stop failed" );
        exit( 1 );
    }

} else {
    fatal( 'Not start or stop:', $command );
}

exit( 0 );

1;
