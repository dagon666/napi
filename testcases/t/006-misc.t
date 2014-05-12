#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(./lib);
use NapiTest;

use Test::More;
use File::Copy;

my $shell = $ENV{NAPI_TEST_SHELL} // "/bin/bash";

# prepare test file
my $test_file = 'video.avi';
my $test_txt = 'video.txt';

my $test_file_path = $NapiTest::testspace . '/' . $test_file;
my $test_txt_path = $NapiTest::testspace . '/' . $test_txt;

copy $NapiTest::assets . '/av1.dat', $test_file_path;

# download with orig extension
NapiTest::qx_napi($shell, " -e orig " . $test_file_path);
is ( -e $test_txt_path =~ s/\.[^\.]+$/\.orig/r, 
		1, 
		"Explicitly specified extension" );

ok ( ! -e $test_txt_path, 
		"Explicitly specified extension (txt file)" );

# skip existing with custom extension
my $o = NapiTest::qx_napi($shell, " -s -e orig " . $test_file_path);
my %o = NapiTest::parse_summary($o);
is ( -e $test_txt_path =~ s/\.[^\.]+$/\.orig/r, 
		1, 
		"Skipping with explicitly specified extension (file test)" );

is ($o{pominieto}, 1, "Number of skipped");

# skip convert 
# my $o = NapiTest::qx_napi($shell, " -f subrip -s -e orig " . $test_file_path);





# NapiTest::clean_testspace();
done_testing();
