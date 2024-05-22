#!/usr/bin/perl
#
# Change admin password.
#
# Copyright (C) 2019 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

use UBOS::Logging;
use UBOS::Utils;

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $apacheUname = $config->getResolve( 'apache2.uname' );
my $adminlogin  = $config->getResolve( 'site.admin.userid' );
my $adminpass   = $config->getResolve( 'site.admin.credential' );
my $ret         = 1;

if( 'upgrade' eq $operation ) {
    my $out;
    my $err;

    my $cmdPrefix1 = "cd '$dir';";
    $cmdPrefix1 .= "sudo -u '$apacheUname'";

    my $cmdPrefix2 .= ' php -d always_populate_raw_post_data=-1';
    $cmdPrefix2 .= ' -d memory_limit=512M';
    $cmdPrefix2 .= ' occ';

    my $getCmd = $cmdPrefix1 . $cmdPrefix2 . ' config:app:get password_policy minLength';
    my $passwordMinLength;

    if( UBOS::Utils::myexec( $getCmd, undef, \$out, \$err )) {
        # No error message; if no value is set, this exits with 1
        $ret = 0;
        $passwordMinLength = 10; # Nextcloud default in 22
    } else {
        $passwordMinLength = $out;
        $passwordMinLength =~ s!^\s+!!;
        $passwordMinLength =~ s!\s+$!!;
    }

    my @cmds = ();
    # Temporarily disable Nextcloud's password rules
    push @cmds, $cmdPrefix1 . $cmdPrefix2 . ' config:app:set password_policy enforceHaveIBeenPwned --value 0';
    push @cmds, $cmdPrefix1 . $cmdPrefix2 . ' config:app:set password_policy enforceNonCommonPassword --value 0';
    push @cmds, $cmdPrefix1 . $cmdPrefix2 . ' config:app:set password_policy minLength --value 8';

    push @cmds, $cmdPrefix1 . ' OC_PASS="' . $adminpass . '"' . $cmdPrefix2 . ' user:resetpassword "' . $adminlogin . '" --password-from-env';

    push @cmds, $cmdPrefix1 . $cmdPrefix2 . ' config:app:set password_policy enforceHaveIBeenPwned --value 1';
    push @cmds, $cmdPrefix1 . $cmdPrefix2 . ' config:app:set password_policy enforceNonCommonPassword --value 1';
    push @cmds, $cmdPrefix1 . $cmdPrefix2 . ' config:app:set password_policy minLength --value ' . $passwordMinLength;

    for my $cmd ( @cmds ) {
        if( UBOS::Utils::myexec( $cmd, undef, \$out, \$err )) {
            error( "$cmd failed:\n$out\n$err" );
            $ret = 0;
        }
    }
}

1;
