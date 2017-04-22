#!/usr/bin/perl
#
# Modify the database info in the restore config.php
#

use strict;
use warnings;

use UBOS::Logging;
use UBOS::Utils;

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $confFile    = "$dir/config/config.php";

my $apacheUname = $config->getResolve( 'apache2.uname' );
my $apacheGname = $config->getResolve( 'apache2.gname' );
my $hostname    = $config->getResolve( 'site.hostname' );

my $dbname      = $config->getResolve( 'appconfig.mysql.dbname.maindb' );
my $dbuser      = $config->getResolve( 'appconfig.mysql.dbuser.maindb' );
my $dbpass      = $config->getResolve( 'appconfig.mysql.dbusercredential.maindb' );
my $dbhost      = $config->getResolve( 'appconfig.mysql.dbhost.maindb' );

my $datadir     = $config->getResolve( 'appconfig.datadir' ) . '/data';

if( 'upgrade' eq $operation ) {

    if( -r $confFile ) {

        my $conf = UBOS::Utils::slurpFile( $confFile );

        unless( $conf =~ s!(['"]dbname['"]\s+=>\s["'])\S*(["'],?)!$1$dbname$2! ) {
            error( 'Cannot find entry dbname in', $confFile, '-- nextcloud10 likely to be flaky' );
        }
        unless( $conf =~ s!(['"]dbhost['"]\s+=>\s["'])\S*(["'],?)!$1$dbhost$2! ) {
            error( 'Cannot find entry dbhost in', $confFile, '-- nextcloud10 likely to be flaky' );
        }
        unless( $conf =~ s!(['"]dbuser['"]\s+=>\s["'])\S*(["'],?)!$1$dbuser$2! ) {
            error( 'Cannot find entry dbuser in', $confFile, '-- nextcloud10 likely to be flaky' );
        }
        unless( $conf =~ s!(['"]dbpassword['"]\s+=>\s["'])\S*(["'],?)!$1$dbpass$2! ) {
            error( 'Cannot find entry dbpassword in', $confFile, '-- nextcloud10 likely to be flaky' );
        }
        unless( $conf =~ s!(['"]trusted_domains['"]\s+=>\s*array\s*\(\s*0\s*=>\s*["'])\S*(\s*['"])!$1$hostname$2!m ) {
            error( 'Cannot find entry trusted_domains in', $confFile, '-- nextcloud10 likely to be flaky' );
        }
        unless( $conf =~ s!(['"]datadirectory['"]\s+=>\s["'])\S*(["'],?)!$1$datadir$2! ) {
            error( 'Cannot find entry datadirectory in', $confFile, '-- nextcloud10 likely to be flaky' );
        }
        UBOS::Utils::saveFile( $confFile, $conf, 0640, $apacheUname, $apacheGname );

    } else {
        error( 'Cannot read config file', $confFile );
    }
}

1;
