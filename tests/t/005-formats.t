#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(./lib);
use NapiTest;

use Test::More;

my $shell = $ENV{NAPI_TEST_SHELL} // "/bin/bash";

# prepare test file
my $test_file = 'video.avi';
my $test_txt = 'video.txt';

my $test_file_path = $NapiTest::testspace . '/' . $test_file;
my $test_txt_path = $NapiTest::testspace . '/' . $test_txt;

copy $NapiTest::assets . '/av1.dat', $test_file_path;
NapiTest::qx_napi($shell, " -f microdvd " . $test_file_path);



NapiTest::clean_testspace();
done_testing();
