#!/usr/bin/perl
#
# Invoke occ upgrade
#
# Copyright (C) 2016 and later, Indie Computing Corp. All rights reserved. License: see package.
#

use strict;
use warnings;

use UBOS::Logging;
use UBOS::Utils;

my $dir            = $config->getResolve( 'appconfig.apache2.dir' );
my $datadir        = $config->getResolve( 'appconfig.datadir' ) . '/data';
my $apacheUname    = $config->getResolve( 'apache2.uname' );
my $context        = $config->getResolve( 'appconfig.context' );
my $contextOrSlash = $config->getResolve( 'appconfig.contextorslash' );
my $hostname       = $config->getResolve( 'site.hostname' );
my $protocol       = $config->getResolve( 'site.protocol' );

my $ret = 1;

if( 'upgrade' eq $operation ) {
# Run occ upgrade
    my $cmdPrefix = "cd '$dir';";
    $cmdPrefix .= "sudo -u '$apacheUname' php";
    $cmdPrefix .= ' -d always_populate_raw_post_data=-1';
    $cmdPrefix .= ' -d memory_limit=512M';
    $cmdPrefix .= ' occ';

    my @cmds = ();
    push @cmds, 'maintenance:mimetype:update-db';
    push @cmds, 'maintenance:mimetype:update-js';
    push @cmds, 'config:system:set allow_local_remote_servers --type boolean --value true';
    push @cmds, 'db:add-missing-columns';
    push @cmds, 'db:add-missing-indices --no-interaction';
    push @cmds, 'db:add-missing-primary-keys';
    push @cmds, 'maintenance:data-fingerprint';

    if( $hostname eq '*' ) {
        # maintenance:update:htaccess needs a value, so we temporarily set one
        push @cmds, "config:system:set overwrite.cli.url '--value=$protocol://localhost$context'";
        push @cmds, 'maintenance:update:htaccess';
        push @cmds, 'config:system:delete overwrite.cli.url';

    } else {
        push @cmds, "config:system:set overwrite.cli.url '--value=$protocol://$hostname$context'";
            # Required so the social app has the correct values:
            # occ config:app:get social cloud_url and social_url
        push @cmds, 'maintenance:update:htaccess';
    }

    push @cmds, "config:system:set htaccess.RewriteBase '--value=$contextOrSlash'";
        # See https://docs.nextcloud.com/server/18/admin_manual/configuration_server/config_sample_php_parameters.html

# Apparently not needed:
#                  "config:system:set overwritehost '--value=$hostname'",
#                  "config:system:set overwriteprotocol '--value=$protocol'",
#                  "config:system:set overwritewebroot '--value=$context'",
    push @cmds, 'config:app:set password_policy enforceNonCommonPassword --value 0';
    push @cmds, 'db:convert-filecache-bigint --no-interaction';

    my $out;
    my $err;

    for my $cmd ( @cmds ) {
        if( UBOS::Utils::myexec( "$cmdPrefix $cmd", undef, \$out, \$err )) {
            error( "occ $cmd failed:\n$out\n$err" );
            $ret = 0;
        }
    }

    if( UBOS::Utils::myexec( "$cmdPrefix upgrade", undef, \$out, \$err )) {
        if( $out =~ m!already latest version! ) {
            # apparently a non-upgrade is an error, with the message on stdout
            # no op
        } elsif( $out =~ m!Updates between multiple major versions and downgrades are unsupported! ) {
            error( <<MSG );
Unfortunately, Nextcloud cannot currently upgrade your installation. This is because you skipped at least
one major Nextcloud version since you last upgraded, and the Nextcloud upgrader does not know how to handle
this yet. You will have to do the upgrade work manually, unfortunately. There is more information at
https://ubos.net/docs/operation/apps/nextcloud/
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
