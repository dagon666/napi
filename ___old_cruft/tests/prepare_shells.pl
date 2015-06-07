#!/usr/bin/perl

use strict;
use warnings;
$|++;


use LWP::Simple;
use Archive::Extract;
use File::Temp;

my $prefix = shift // "/opt/napi/bash";

my $url = "http://ftp.gnu.org/gnu/bash";

my @versions = qw/
    bash-2.04.tar.gz
    bash-2.05.tar.gz
    bash-3.0.tar.gz
    bash-3.1.tar.gz
    bash-3.2.48.tar.gz
    bash-3.2.tar.gz
    bash-4.0.tar.gz
    bash-4.1.tar.gz
    bash-4.2.tar.gz
    bash-4.3.tar.gz
    /;

die "Shell Source directory already exists - assuming that all sources already have been downloaded and compiled\n"
    if ( -e $prefix && -d $prefix );

STDOUT->autoflush(1);

foreach (@versions) {
    my ($version) = m/^bash-(.*)?\.tar\.gz$/;
    my $shell = 'bash-' . $version;

    my $wdir = File::Temp::tempdir( CLEANUP => 1 );

    my $tgz_path = $wdir . '/' . $_;
    my $src_path = $wdir . '/' . $shell;

    my $dst_path = $prefix . '/' . $shell;

    print "Downloading shell: [$_]\n"
        and getstore( $url . '/' . $_, $tgz_path ) unless ( -e $tgz_path );

    my $ae = Archive::Extract->new( archive => $tgz_path );
    $ae->extract( to => $wdir ) and print "Unpacked [$_]\n";

    # build it
    print "Building [$shell]\n";
    if (chdir($src_path)) {
        system("./configure --prefix $dst_path && make install");
        chdir;
    }
}
