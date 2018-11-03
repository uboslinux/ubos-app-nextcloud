#!/usr/bin/perl
#
# Prime the caches so Nextcloud comes up faster
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

use UBOS::Logging;
use UBOS::Utils;

if(    'install' eq $operation
    || 'upgrade' eq $operation )
{
    my $adminlogin  = $config->getResolve( 'site.admin.userid' );
    my $adminpass   = $config->getResolve( 'site.admin.credential' );

    my $proto    = $config->getResolve( 'site.protocol' );
    my $hostname = $config->getResolve( 'site.hostname' );
    my $context  = $config->getResolve( 'appconfig.context' );

    my $url;
    if( '*' eq $hostname ) {
        $url = "$proto://127.0.0.1$context";
    } else {
        $url = "$proto://$hostname$context";
    }

    my $ok       = 1; # don't continue if something failed, but don't interrupt install; not critical

    my $cookieFile = File::Temp->new();
    my $loginData;

info( "XXX ABOUT TO GO TO FRONT PAGE" );
    my $out;
    if( $ok && UBOS::Utils::myexec( "curl --insecure --cookie-jar '$cookieFile' -b '$cookieFile' $url/login", undef, \$out, \$out )) {
        warning( 'curl prime-caches (1) failed for Nextcloud:', $out );
        $ok = 0;

    } else {
        if( $out =~ m!<input.*name="requesttoken".*value="([^"]+)"! ) {
            my $requestToken = $1;
            $loginData  = "user=$adminlogin";
            $loginData .= "&password=$adminpass";
            $loginData .= "&requesttoken=$requestToken";
            $loginData .= '&timezone=Etc/UTC';
            $loginData .= '&timezone_offset=0';

info( "XXX request token is $requestToken" );
info( "XXX loginData is $loginData" );

        } else {
            warning( 'Nextcloud login page did not contain requesttoken', $out );
            $ok = 0;
        }
    }
    getc();

    if( $ok ) {
info( "XXX ABOUT TO LOGIN" );
        if( UBOS::Utils::myexec( "curl --insecure --cookie-jar '$cookieFile' -b '$cookieFile' -L $url/login -d $loginData", undef, \$out, \$out )) {
            warning( 'curl prime-caches (2) failed for Nextcloud:', $out );
            $ok = 0;
        }
    }
}

1;
