#!/usr/bin/perl
#
# Perform the installation using occ.
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $apacheUname    = $config->getResolve( 'apache2.uname' );
my $apacheGname    = $config->getResolve( 'apache2.gname' );

my $appConfigId    = $config->getResolve( 'appconfig.appconfigid' );
my $dir            = $config->getResolve( 'appconfig.apache2.dir' );
my $context        = $config->getResolve( 'appconfig.context' );
my $contextOrSlash = $config->getResolve( 'appconfig.contextorslash' );
my $datadir        = $config->getResolve( 'appconfig.datadir' ) . '/data';
my $dbname         = $config->getResolve( 'appconfig.mysql.dbname.maindb' );
my $dbuser         = $config->getResolve( 'appconfig.mysql.dbuser.maindb' );
my $dbpass         = $config->getResolve( 'appconfig.mysql.dbusercredential.maindb' );
my $dbhost         = $config->getResolve( 'appconfig.mysql.dbhost.maindb' );

my $adminlogin     = $config->getResolve( 'site.admin.userid' );
my $adminpass      = $config->getResolve( 'site.admin.credential' );
my $adminemail     = $config->getResolve( 'site.admin.email' );
my $hostname       = $config->getResolve( 'site.hostname' );
my $protocol       = $config->getResolve( 'site.protocol' );

my $confFile       = "$dir/config/config.php";

my $ret = 1;

if( 'install' eq $operation ) {

    my $cmdPrefix;
    $cmdPrefix = "cd '$dir';";
    $cmdPrefix .= "sudo -u '$apacheUname' php";
    $cmdPrefix .= ' -d always_populate_raw_post_data=-1';
    $cmdPrefix .= ' -d memory_limit=512M';

    $cmdPrefix .= ' occ';

    my @cmds = ();

    push @cmds, 'maintenance:install'
                . ' --database "mysql"'
                . " --database-name '$dbname'"
                . " --database-user '$dbuser'"
                . " --database-pass '$dbpass'"
                . " --database-host '$dbhost'"
                . " --admin-user '$adminlogin'"
                . " --admin-pass '$adminpass'"
                . " --admin-email '$adminemail'"
                . " --data-dir '$datadir'"
                . ' -n'; # non-interactive

    push @cmds, 'config:system:set syslog_tag --value=nextcloud@' . $appConfigId;
    push @cmds, 'config:system:set appstoreenabled --type boolean --value false';
    push @cmds, 'config:system:set mail_smtpmode --value=smtp';
    push @cmds, "config:system:set trusted_domains 0 --value '$hostname'";
    push @cmds, 'config:system:set log_type --value=systemd';
    push @cmds, 'config:system:set mysql.utf8mb4 --type boolean --value=true';
    push @cmds, 'config:system:set allow_local_remote_servers --type boolean --value true';

    unless( $hostname eq '*' ) {
        push @cmds, "config:system:set overwrite.cli.url '--value=$protocol://$hostname$context'";
            # Required so the social app has the correct values:
            # occ config:app:get social cloud_url and social_url
    }
    push @cmds, "config:system:set htaccess.RewriteBase '--value=$contextOrSlash'";
        # See https://docs.nextcloud.com/server/18/admin_manual/configuration_server/config_sample_php_parameters.html

# Apparently not needed:
#            "config:system:set overwritehost '--value=$hostname'",
#            "config:system:set overwriteprotocol '--value=$protocol'",
#            "config:system:set overwritewebroot '--value=$context'",
    push @cmds, 'db:add-missing-indices --no-interaction';
    push @cmds, 'db:convert-filecache-bigint --no-interaction';
    push @cmds, 'background:cron';
    push @cmds, 'app:disable updatenotification';
    push @cmds, 'config:app:set password_policy enforceNonCommonPassword --value 0';
    push @cmds, 'maintenance:update:htaccess';

    my $out;
    my $err;

    for my $cmd ( @cmds ) {
        if( UBOS::Utils::myexec( "$cmdPrefix $cmd", undef, \$out, \$out )) {
            error( "Nextcloud command failed:\n$cmd\n$out" );
            $ret = 0;
        }
    }
}

$ret;


