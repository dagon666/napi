#!/usr/bin/perl

use strict;
use warnings;
$|++;

use LWP::Simple;
use Archive::Extract;
use File::Find;
use File::Temp;

my $assets_tgz = "napi_testdata.tar.gz";
my $url = "https://www.dropbox.com/s/zm53c23bu7o1n1d/${assets_tgz}?dl=1";
my $assets_path = shift // "/opt/napi/testdata";

my $wdir = File::Temp::tempdir( CLEANUP => 1 );

sub print_status {
    my ($msg, $coderef, $expected) = @_;
    print $msg . " ... ";
    my $retval = &{$coderef}();
    print $retval == $expected ? "OK" : "FAIL";
    print "\n";
    return $retval;
}

sub on_success {
    my ($retval, $coderef, $expected) = @_;
    $coderef->() if $retval == $expected;
}

on_success(
    print_status(
        "Downloading $assets_tgz",
        sub {
            getstore( $url, $wdir . '/' . $assets_tgz );
        },
        200),
    sub {
        die "Unable to create the architecture independent data directory\n"
            unless ( -e $assets_path || mkdir ($assets_path) );

        print_status(
            "Unpacking assets",
            sub {
                my $archive = $wdir . '/' . $assets_tgz;
                my $ae = Archive::Extract->new(
                    archive => $archive );

                if ($ae->extract( to => $assets_path )) {
                    File::Find::find(sub { chmod(0755, $_); }, ($assets_path));
                    return 1;
                }

                return 0;
            },
            1
        );
    },
    200
);
