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

NapiTest::qx_napi($shell, " -C utf8 " . $test_file_path);
like(`file -b $test_txt_path`, 
		qr/UTF-8/, "Checking conversion result for UTF-8");

NapiTest::qx_napi($shell, " -C ISO_8859-2 " . $test_file_path);
like(`file -b $test_txt_path`, 
		qr/ISO-8859/, "Checking conversion result for ISO");

NapiTest::qx_napi($shell, " -s -C utf8 " . $test_file_path);
like(`file -b $test_txt_path`, 
		qr/ISO-8859/, "Checking conversion result for ISO with skip option");

NapiTest::clean_testspace();
done_testing();
