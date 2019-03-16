#!/usr/bin/perl
#
# Perform the installation using occ.
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $apacheUname = $config->getResolve( 'apache2.uname' );
my $apacheGname = $config->getResolve( 'apache2.gname' );

my $appConfigId = $config->getResolve( 'appconfig.appconfigid' );
my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $datadir     = $config->getResolve( 'appconfig.datadir' ) . '/data';
my $dbname      = $config->getResolve( 'appconfig.mysql.dbname.maindb' );
my $dbuser      = $config->getResolve( 'appconfig.mysql.dbuser.maindb' );
my $dbpass      = $config->getResolve( 'appconfig.mysql.dbusercredential.maindb' );
my $dbhost      = $config->getResolve( 'appconfig.mysql.dbhost.maindb' );

my $adminlogin  = $config->getResolve( 'site.admin.userid' );
my $adminpass   = $config->getResolve( 'site.admin.credential' );
my $adminemail  = $config->getResolve( 'site.admin.email' );
my $hostname    = $config->getResolve( 'site.hostname' );

my $confFile    = "$dir/config/config.php";

my $ret = 1;

if( 'install' eq $operation ) {

    my $cmdPrefix;
    my $out;
    my $cmd;

    $cmdPrefix = "cd '$dir';";
    $cmdPrefix .= "sudo -u '$apacheUname' php";
    $cmdPrefix .= ' -d always_populate_raw_post_data=-1';
    $cmdPrefix .= ' -d memory_limit=512M';

    $cmdPrefix .= ' occ';

    for my $cmd (
            'maintenance:install'
                . ' --database "mysql"'
                . " --database-name '$dbname'"
                . " --database-user '$dbuser'"
                . " --database-pass '$dbpass'"
                . " --database-host '$dbhost'"
                . " --admin-user '$adminlogin'"
                . " --admin-pass '$adminpass'"
                . " --admin-email '$adminemail'"
                . " --data-dir '$datadir'"
                . ' -n', # non-interactive
            'config:system:set syslog_tag --value=nextcloud@' . $appConfigId,
            'config:system:set appstoreenabled --type boolean --value false',
            'config:system:set mail_smtpmode --value=smtp',
            "config:system:set trusted_domains 0 --value '$hostname'",
            'config:system:set log_type --value=systemd',
            'db:add-missing-indices --no-interaction',
            'db:convert-filecache-bigint --no-interaction',
            'background:cron',
            'app:disable updatenotification' )
    {
        if( UBOS::Utils::myexec( "$cmdPrefix $cmd", undef, \$out, \$out )) {
            error( "Nextcloud command failed:\n$cmd\n$out" );
            $ret = 0;
        }
    }
}

$ret;


