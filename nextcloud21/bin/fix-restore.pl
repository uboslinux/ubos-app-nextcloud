#!/usr/bin/perl
#
# Modify the database info in the restore config.php
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

use UBOS::Logging;
use UBOS::Utils;

my $dir            = $config->getResolve( 'appconfig.apache2.dir' );
my $confFile       = "$dir/config/config.php";
my $instanceIdFile = "$dir/config/instanceid.txt"; # old ownCloud only
my $pwSaltFile     = "$dir/config/passwordsalt.txt"; # old ownCloud only
my $versionFile    = "$dir/version.php";

my $apacheUname = $config->getResolve( 'apache2.uname' );
my $apacheGname = $config->getResolve( 'apache2.gname' );
my $hostname    = $config->getResolve( 'site.hostname' );

my $dbname      = $config->getResolve( 'appconfig.mysql.dbname.maindb' );
my $dbuser      = $config->getResolve( 'appconfig.mysql.dbuser.maindb' );
my $dbpass      = $config->getResolve( 'appconfig.mysql.dbusercredential.maindb' );
my $dbhost      = $config->getResolve( 'appconfig.mysql.dbhost.maindb' );

my $appconfigid = $config->getResolve( 'appconfig.appconfigid' );
my $datadir     = $config->getResolve( 'appconfig.datadir' ) . '/data';

if( 'upgrade' eq $operation ) {

    if( -r $confFile ) {
        # We have a conf file, so let's upgrade. This is very likely Nextcloud

        # Best to execute this to get the values we need. This will also remove
        # all traces of config info provided only later by accessories
        # (like the Redis Cache)

        my $php = <<PHP;
<?php
require "$confFile";
print( \$CONFIG['passwordsalt'] . "\n" );
print( \$CONFIG['secret'] . "\n" );
print( \$CONFIG['version'] . "\n" );
print( \$CONFIG['instanceid'] . "\n" );
PHP
        my $out;
        my $err;
        if( UBOS::Utils::myexec( 'php', $php, \$out, \$err )) {
            error( 'PHP execution failed:', $php, $err );
        }
        my( $passwordsalt, $secret, $version, $instanceid ) = split( /\n/, $out );

        my $config = <<CONFIG;
<?php
\$CONFIG = array (
  'passwordsalt' => '$passwordsalt',
  'secret' => '$secret',
  'trusted_domains' =>
    array (
      0 => '$hostname',
    ),
  'datadirectory' => '$datadir',
  'dbtype' => 'mysql',
  'version' => '$version',
  'overwrite.cli.url' => 'http://localhost',
  'dbname' => '$dbname',
  'dbhost' => '$dbhost',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'dbuser' => '$dbuser',
  'dbpassword' => '$dbpass',
  'installed' => true,
  'instanceid' => '$instanceid',
  'syslog_tag' => 'nextcloud\@$appconfigid',
  'appstoreenabled' => false,
  'mail_smtpmode' => 'smtp',
  'log_type' => 'systemd',
  'mysql.utf8mb4' => true
);
CONFIG

        UBOS::Utils::saveFile( $confFile, $config, 0640, $apacheUname, $apacheGname );

    } else {
        # We don't have a conf file, so this might be an old ownCloud upgrade

        # Pretend that we recover from an old ownCloud version
        my $version = '10.0.0.12';

        # InstanceId
        my $instanceId;
        if( -r $instanceIdFile ) {
            $instanceId = UBOS::Utils::slurpFile( $instanceIdFile );
            UBOS::Utils::deleteFile( $instanceIdFile );
        } else {
            $instanceId = UBOS::Utils::randomHex( 10 );
        }

        # Pw salt
        my $pwSalt;
        if( -r $pwSaltFile ) {
            $pwSalt = UBOS::Utils::slurpFile( $pwSaltFile );
            UBOS::Utils::deleteFile( $pwSaltFile );
        } else {
            error( 'Cannot recover password salt. Existing Nextcloud users may not be able to log in.' );
            $pwSalt = '';
        }

        # The secret seems to be new, so we generate it
        my $secret = '';
        for( my $i=0 ; $i<48 ; ++$i ) {
            $secret .= (0..9, "a".."z", "A".."Z", "+", "/")[rand 64];
        }

        my $conf = <<CONF;
<?php
\$CONFIG = array (
  'passwordsalt' => '$pwSalt/DM4IfXh0GI6b',
  'secret' => '$secret',
  'trusted_domains' =>
  array (
    0 => '$hostname',
  ),
  'datadirectory' => '$datadir',
  'overwrite.cli.url' => 'http://localhost',
  'dbtype' => 'mysql',
  'version' => '$version',
  'dbname' => '$dbname',
  'dbhost' => '$dbhost',
  'dbport' => '',
  'dbtableprefix' => '',
  'dbuser' => '$dbuser',
  'dbpassword' => '$dbpass',
  'installed' => true,
  'instanceid' => '$instanceId',
  'appstoreenabled' => false,
);
CONF

        UBOS::Utils::saveFile( $confFile, $conf, 0640, $apacheUname, $apacheGname );
    }
}

1;
