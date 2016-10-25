#!/usr/bin/perl
#
# Perform the installation using occ.
#

use strict;

use UBOS::Logging;
use UBOS::Utils;
use POSIX;

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $datadir     = $config->getResolve( 'appconfig.datadir' ) . '/data';
my $apacheUname = $config->getResolve( 'apache2.uname' );
my $hostname    = $config->getResolve( 'site.hostname' );

my $dbname      = $config->getResolve( 'appconfig.mysql.dbname.maindb' );
my $dbuser      = $config->getResolve( 'appconfig.mysql.dbuser.maindb' );
my $dbpass      = $config->getResolve( 'appconfig.mysql.dbusercredential.maindb' );
my $dbhost      = $config->getResolve( 'appconfig.mysql.dbhost.maindb' );

my $hostname    = $config->getResolve( 'site.hostname' );
my $adminlogin  = $config->getResolve( 'site.admin.userid' );
my $adminpass   = $config->getResolve( 'site.admin.credential' );

my $ret = 1;


if( 'install' eq $operation ) {

    my $cmd = "cd '$dir';";
    $cmd .= "sudo -u '$apacheUname' php";
    $cmd .= " -d 'open_basedir=$dir:/tmp/:/usr/share/:$datadir'";
    $cmd .= ' -d always_populate_raw_post_data=-1';
    $cmd .= ' -d extension=posix.so';
    $cmd .= ' occ maintenance:install';
    $cmd .= ' --database "mysql"';
    $cmd .= " --database-name '$dbname'";
    $cmd .= " --database-user '$dbuser'";
    $cmd .= " --database-pass '$dbpass'";
    $cmd .= " --database-host '$dbhost'";
    $cmd .= " --admin-user '$adminlogin'";
    $cmd .= " --admin-pass '$adminpass'";
    $cmd .= " --data-dir '$datadir'";
    $cmd .= ' -n'; # non-interactive

    my $out;
    my $err;
    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$err )) {
        # something else happened
        error( "occ maintenance:install failed:\n$out\n$err" );
        $ret = 0;
    }
}

$ret;


