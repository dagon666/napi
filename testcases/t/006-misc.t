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

#>TESTSPEC
#
# Brief:
# 
# Download subtitles with a custom extension specified
#
# Preconditions:
# - media file for which the subtitles are available
#
# Procedure:
# - specify a custom extension for the probed media file
#
# Expected results:
# - subtitles should be downloaded and the resulting 
# subtitles file should have the specified extension
# 
# - the subtitle file with a default txt extension
# shouldn't exist
#
NapiTest::qx_napi($shell, " -e orig " . $test_file_path);
is ( -e $test_txt_path =~ s/\.[^\.]+$/\.orig/r, 
		1, 
		"Explicitly specified extension" );

ok ( ! -e $test_txt_path, 
		"Explicitly specified extension (txt file)" );


#>TESTSPEC
#
# Brief:
# 
# Download subtitles with a custom extension specified and skip option enabled
#
# Preconditions:
# - media file for which the subtitles are available
# - subtitles file should (with a custom extension) should already exist in the FS
#
# Procedure:
# - specify a custom extension for the probed media file
# - specify the skip flag
#
# Expected results:
# - subtitles should not be downloaded twice
# - the skip counter should be reflected in the summary
# 
my $o = NapiTest::qx_napi($shell, " -s -e orig " . $test_file_path);
my %o = NapiTest::parse_summary($o);
is ( -e $test_txt_path =~ s/\.[^\.]+$/\.orig/r, 
		1, 
		"Skipping with explicitly specified extension (file test)" );

is ($o{pominieto}, 1, "Number of skipped");


#>TESTSPEC
#
# Brief:
# 
# Download subtitles with a custom extension specified, skip option enabled and format conversion request
#
# Preconditions:
# - napi.sh & subotage.sh should be visible in public $PATH
# - media file for which the subtitles are available
# - subtitles file should (with a custom extension) should already exist in the FS
#
# Procedure:
# - specify a custom extension for the probed media file
# - specify the skip flag
# - specify conversion request
#
# Expected results:
# - original subtitles should not be downloaded twice
# - the original subtitles should be converted to requested format
# - after conversion both files should exist in the filesystem (original one with prefix prepended)
# 
$o = NapiTest::qx_napi($shell, " -f subrip -s -e orig " . $test_file_path);
%o = NapiTest::parse_summary($o);
is ( -e $test_txt_path =~ s/\.[^\.]+$/\.srt/r, 
		1, 
		"Testing skipping with already downloaded original" );

ok ( ! -e $test_txt_path =~ s/\.[^\.]+$/\.orig/r, 
		"Checking if original file has been removed" );

is ($o{pobrano}, 0, "Number of skipped");
is ($o{przekonw}, 1, "Number of converted");


# NapiTest::clean_testspace();
done_testing();
