#!/usr/bin/perl

use strict;
use warnings;
$|++;

use lib qw(./napitester/lib/perl5);
use GithubInstaller;
use NetInstall;

GithubInstaller::preparePkg("dagon666",
    "scpmocker",
    "0.2",
    \&NetInstall::pythonInstall
);

__END__
