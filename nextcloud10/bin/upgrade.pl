#!/usr/bin/perl
#
# Invoke occ upgrade
#

use strict;
use warnings;

use UBOS::Logging;
use UBOS::Utils;

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $datadir     = $config->getResolve( 'appconfig.datadir' ) . '/data';
my $apacheUname = $config->getResolve( 'apache2.uname' );
my $ret         = 1;

if( 'upgrade' eq $operation ) {
# Run occ upgrade
    my $cmd = "cd '$dir';";
    $cmd .= "sudo -u '$apacheUname' php";
    $cmd .= " -d 'open_basedir=$dir:/tmp/:/usr/share/:$datadir'";
    $cmd .= ' -d always_populate_raw_post_data=-1';
    $cmd .= ' -d extension=posix.so';
    $cmd .= ' occ upgrade';

    my $out;
    my $err;
    if( UBOS::Utils::myexec( $cmd, undef, \$out, \$err )) {
        if( $out =~ m!already latest version! ) {
            # apparently a non-upgrade is an error, with the message on stdout
            # no op
        } elsif( $out =~ m!Updates between multiple major versions and downgrades are unsupported! ) {
            error( <<MSG );
Unfortunately, Nextcloud cannot currently upgrade your installation. This is because you skipped at least
one major Nextcloud version since you last upgraded, and the Nextcloud upgrader does not know how to handle
this yet. You will have to do the upgrade work manually, unfortunately.
MSG
            $ret = 0;

        } else {
            # something else happened
            error( "occ upgrade failed:\n$out\n$err" );
            $ret = 0;
        }
    }
}

$ret;
