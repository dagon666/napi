#!/usr/bin/perl

use strict;
use warnings;
$|++;

use lib qw(./common/lib/perl5);
use NetInstall;

my $prefix = shift // "/opt/napi/bash";
my $baseUrl = "http://ftp.gnu.org/gnu/bash";
my @versions = (
    { package => 'bash-2.04.tar.gz', args => undef },
    { package => 'bash-2.05.tar.gz', args => undef },
    { package => 'bash-3.0.tar.gz',  args => undef },
    { package => 'bash-3.1.tar.gz',  args => undef },
    { package => 'bash-3.2.tar.gz',  args => [ '--disable-nls' ] },
    { package => 'bash-4.0.tar.gz',  args => undef },
    { package => 'bash-4.1.tar.gz',  args => undef },
    { package => 'bash-4.2.tar.gz',  args => undef },
    { package => 'bash-4.3.tar.gz',  args => undef },
);

die "Shell Source directory already exists - assuming that all sources already have been downloaded and compiled\n"
    if ( -e $prefix && -d $prefix );

STDOUT->autoflush(1);
foreach (@versions) {
    my $workDir = File::Temp::tempdir( CLEANUP => 1 );

    my ($version) = $_->{'package'} =~ m/^bash-(.*)?\.tar\.gz$/;
    my $shell = 'bash-' . $version;
    my $tgzPath = $workDir . '/' . $_->{'package'};
    my $srcPath = $workDir . '/' . $shell;
    my $dstPath = $prefix . '/' . $shell;
    my $url = $baseUrl . '/' . $_->{'package'};

    NetInstall::prepareTgz($url, $workDir,
        $tgzPath, $srcPath,
        $dstPath, \&NetInstall::automakeInstall, $_->{'args'});
}
