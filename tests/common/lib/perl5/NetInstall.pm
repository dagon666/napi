#!/usr/bin/perl

use strict;
use warnings;
$|++;

use Exporter();
use Carp;
use LWP::Simple;
use Archive::Extract;
use File::Temp;

package NetInstall;

sub getArchive {
    my ($url, $dstPath) = @_;
    print "Downloading...[$url]\n";
    my $code = LWP::Simple::getstore($url, $dstPath);
    print "HTTP reponse: [$code]\n";
}

sub extractArchive {
    my ($tgzPath, $dstPath) = @_;
    print "Extracting...\n";
    my $ae = Archive::Extract->new(archive => $tgzPath);
    $ae->extract(to => $dstPath)
        and print "Unpacked\n";
}

sub install {
    my ($srcPath, $dstPath, $installCmd, $extraArgs) = @_;
    print "Building & installing...\n";
    if (chdir($srcPath)) {
        $installCmd->($dstPath, $extraArgs);
        chdir;
    }
}

sub pythonInstall {
    system("ls -l && python ./setup.py install");
}

sub cmakeInstall {
    system("mkdir build && cd build && cmake .. && make && make install");
}

sub automakeInstall {
    my $dstPath = shift // "";
    my $extraArgs = shift // [];
    my $cmd = "./configure " .
        (length($dstPath) ? "--prefix $dstPath ": "") .
        "@{ $extraArgs } " .
        "&& make " .
        "&& make install";
    system($cmd);
}

sub prepareTgz {
    my ($url, $workDir,
        $tgzPath, $srcPath,
        $dstPath, $installCmd, $extraArgs) = @_;

    getArchive($url, $tgzPath) ||
        die "Unable to download archive\n";

    extractArchive($tgzPath, $workDir) ||
        die "Unable to extract archive\n";

    install($srcPath, $dstPath, $installCmd, $extraArgs);
}

1;
