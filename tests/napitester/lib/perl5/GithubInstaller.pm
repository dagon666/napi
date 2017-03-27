#!/usr/bin/perl

use strict;
use warnings;

use Exporter();
use Carp;

use NetInstall;

package GithubInstaller;

sub preparePkg {
    my $user = shift;
    my $pkg = shift;
    my $version = shift;
    my $installCmd = shift;

    my $upId = "${user}/${pkg}";
    my $workDir = File::Temp::tempdir(CLEANUP => 1);
    my $url = "https://github.com/${upId}/archive/v${version}.tar.gz";
    my $tgzPath = $workDir . "/v${version}.tgz";
    my $srcPath = $workDir . "/${pkg}-${version}";

    NetInstall::prepareTgz($url, $workDir,
        $tgzPath, $srcPath,
        "", $installCmd);
}

1;
