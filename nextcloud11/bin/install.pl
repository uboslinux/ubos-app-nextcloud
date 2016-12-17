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

    my $cmd = "cd '$dir';";
    $cmd .= "sudo -u '$apacheUname' php";
    $cmd .= ' -d always_populate_raw_post_data=-1';
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
    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$out )) {
        # something else happened
        error( "occ maintenance:install failed:\n$cmd\n$out" );
        $ret = 0;
    }

    # need to insert trusted_domains into config file
    if( -r $confFile ) {
        my $conf = UBOS::Utils::slurpFile( $confFile );

        unless( $conf =~ s!(['"]trusted_domains['"]\s+=>\s*array\s*\(\s*0\s*=>\s*["'])\S*(\s*['"])!$1$hostname$2!m ) {
            error( 'Cannot find entry trusted_domains in', $confFile, '-- nextcloud10 likely to be flaky' );
        }
        UBOS::Utils::saveFile( $confFile, $conf, 0640, $apacheUname, $apacheGname );

    } else {
        error( 'Cannot read config file', $confFile );
    }
}

$ret;


