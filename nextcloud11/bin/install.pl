#!/usr/bin/perl
#
# Perform the installation using occ.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;

my $apacheUname = $config->getResolve( 'apache2.uname' );
my $apacheGname = $config->getResolve( 'apache2.gname' );

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $datadir     = $config->getResolve( 'appconfig.datadir' ) . '/data';
my $dbname      = $config->getResolve( 'appconfig.mysql.dbname.maindb' );
my $dbuser      = $config->getResolve( 'appconfig.mysql.dbuser.maindb' );
my $dbpass      = $config->getResolve( 'appconfig.mysql.dbusercredential.maindb' );
my $dbhost      = $config->getResolve( 'appconfig.mysql.dbhost.maindb' );

my $adminlogin  = $config->getResolve( 'site.admin.userid' );
my $adminpass   = $config->getResolve( 'site.admin.credential' );
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
    $cmdPrefix .= ' occ';

    $cmd = $cmdPrefix;
    $cmd .= ' maintenance:install';
    $cmd .= ' --database "mysql"';
    $cmd .= " --database-name '$dbname'";
    $cmd .= " --database-user '$dbuser'";
    $cmd .= " --database-pass '$dbpass'";
    $cmd .= " --database-host '$dbhost'";
    $cmd .= " --admin-user '$adminlogin'";
    $cmd .= " --admin-pass '$adminpass'";
    $cmd .= " --data-dir '$datadir'";
    $cmd .= ' -n'; # non-interactive

    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$out )) {
        # something else happened
        error( "Nextcloud command failed:\n$cmd\n$out" );
        $ret = 0;
    }

    $cmd = $cmdPrefix;
    $cmd .= ' config:system:set appstoreenabled --type boolean --value false';

    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$out )) {
        # something else happened
        error( "Nextcloud command failed:\n$cmd\n$out" );
        $ret = 0;
    }

    $cmd = $cmdPrefix;
    $cmd .= ' config:system:set trusted_domains 0 --value ' . $hostname;

    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$out )) {
        # something else happened
        error( "Nextcloud command failed:\n$cmd\n$out" );
        $ret = 0;
    }
}

$ret;


