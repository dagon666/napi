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
my $test_orig_txt = 'ORIG_video.txt';

my $test_file_path = $NapiTest::testspace . '/' . $test_file;
my $test_txt_path = $NapiTest::testspace . '/' . $test_txt;
my $test_orig_txt_path = $NapiTest::testspace . '/' . $test_orig_txt;

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
my $o = NapiTest::qx_napi($shell, " --stats -s -e orig " . $test_file_path);
my %o = NapiTest::parse_summary($o);
is ( -e $test_txt_path =~ s/\.[^\.]+$/\.orig/r, 
		1, 
		"Skipping with explicitly specified extension (file test)" );

is ($o{skip}, 1, "Number of skipped");


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
$o = NapiTest::qx_napi($shell, " --stats -f subrip -s -e orig " . $test_file_path);
%o = NapiTest::parse_summary($o);
is ( -e $test_txt_path =~ s/\.[^\.]+$/\.srt/r, 
		1, 
		"testing skipping with already downloaded original" );

ok ( ! -e $test_txt_path =~ s/\.[^\.]+$/\.orig/r, 
		"checking if original file has been removed" );

is ($o{ok}, 0, "number of skipped");
is ($o{conv}, 1, "number of converted");
NapiTest::clean_testspace();


#>TESTSPEC
#
# Brief:
# Verify skipping with abbreviation specified
#
# Preconditions:
# - download subs for a media file
# - media file for which the subtitles are available
#
# Procedure:
# - specify skip flag
# - specify abbrev=AB, conv_abbrev=CAB
# - try to download subs
#
# Expected results:
# - subtitles shouldn't be downloaded
# - existing subtitles should be copied to the new filename (containing abbrev)
#
copy $NapiTest::assets . '/av1.dat', $test_file_path;
NapiTest::qx_napi($shell, " -s " . $test_file_path);
ok ( -e $test_txt_path,
		"check if preconditions are met" );

$o = NapiTest::qx_napi($shell, " --stats -s -a AB --conv-abbrev CAB " . $test_file_path);
%o = NapiTest::parse_summary($o);
ok ( -e $test_txt_path,
		"check if original file still exists" );

ok ( -e $test_txt_path =~ s/\.([^\.]+)$/\.AB\.$1/r,
		"check if file with abbreviation exists" );

is ($o{skip}, 1, "number of skipped");
is ($o{ok}, 0, "number of downloaded");


#>TESTSPEC
#
# Brief:
# Verify skipping with abbreviation specified
#
# Preconditions:
# - subs for a media file
# - media file for which the subtitles are available
#
# Procedure:
# - specify skip flag
# - specify abbrev=AB, conv_abbrev=CAB
# - try to download subs
#
# Expected results:
# - subtitles shouldn't be downloaded
#
$o = NapiTest::qx_napi($shell, " --stats -s -a AB --conv-abbrev CAB " . $test_file_path);
%o = NapiTest::parse_summary($o);
ok ( -e $test_txt_path,
		"check if original file still exists" );

ok ( -e $test_txt_path =~ s/\.([^\.]+)$/\.AB\.$1/r,
		"check if file with abbreviation exists" );
is ($o{skip}, 1, "number of skipped");
is ($o{ok}, 0, "number of downloaded");
NapiTest::clean_testspace();


#>TESTSPEC
#
# Brief:
# Verify skipping with abbreviation specified and -M flag (move instead of copy)
#
# Preconditions:
# - download subs for a media file
# - media file for which the subtitles are available
#
# Procedure:
# - specify skip flag
# - specify abbrev=AB, conv_abbrev=CAB
# - specify -M flag
# - try to download subs
#
# Expected results:
# - subtitles shouldn't be downloaded
#
copy $NapiTest::assets . '/av1.dat', $test_file_path;
NapiTest::qx_napi($shell, " -s " . $test_file_path);
ok ( -e $test_txt_path,
		"check if preconditions are met" );

$o = NapiTest::qx_napi($shell, " -M --stats -s -a AB --conv-abbrev CAB " . $test_file_path);
%o = NapiTest::parse_summary($o);
ok ( ! -e $test_txt_path,
		"check if original file has been moved" );

ok ( -e $test_txt_path =~ s/\.([^\.]+)$/\.AB\.$1/r,
		"check if file with abbreviation exists" );

is ($o{skip}, 1, "number of skipped");
is ($o{ok}, 0, "number of downloaded");
NapiTest::clean_testspace();


#>TESTSPEC
#
# Brief:
# 
# Download subtitles with both abbrev and conv-abbrev specified and format conversion request
#
# Preconditions:
# - napi.sh & subotage.sh should be visible in public $PATH
# - media file for which the subtitles are available
#
# Procedure:
# - specify the abbreviation as AB
# - specify the conv-abbreviation as CAB
# - specify conversion request
#
# Expected results:
# - the subtitles should be downloaded and converted to the requested format
# - the original subtitles should be renamed to default prefix and should contain the abbreviation in the filename
# - after conversion both files should exist in the filesystem (original one with prefix prepended)
# - converted file should have both abbrev and conversion abbrev inserted into the file name
# 
copy $NapiTest::assets . '/av1.dat', $test_file_path;
$o = NapiTest::qx_napi($shell, " --stats -f subrip -s -a AB --conv-abbrev CAB " . $test_file_path);
%o = NapiTest::parse_summary($o);

ok ( -e $test_orig_txt_path =~ s/\.([^\.]+)$/\.AB\.$1/r,
		"check for original file" );

ok ( -e $test_txt_path =~ s/\.([^\.]+)$/\.AB\.CAB\.srt/r,
		"checking for converted file and abbreviations" );

is ($o{ok}, 1, "number of downloaded");
is ($o{conv}, 1, "number of converted");


#>TESTSPEC
#
# Brief:
# 
# check skipping with conversion requested and abbreviations specified
#
# Preconditions:
# - the ORIG_ file should be present
# - the converted file should be absent
# - napi.sh & subotage.sh should be visible in public $PATH
# - media file for which the subtitles are available
#
# Procedure:
# - specify the abbreviation as AB
# - specify the conv-abbreviation as CAB
# - specify conversion request
# - specify the skip flag
#
# Expected results:
# - the subtitles shouldn't be downloaded original available file should be converted
# - after conversion both files should exist in the filesystem (original one with prefix prepended)
# - converted file should have both abbrev and conversion abbrev inserted into the file name
# 
unlink $test_txt_path =~ s/\.([^\.]+)$/\.AB\.CAB\.srt/r;
$o = NapiTest::qx_napi($shell, " --stats -f subrip -s -a AB --conv-abbrev CAB " . $test_file_path);
%o = NapiTest::parse_summary($o);

ok ( -e $test_orig_txt_path =~ s/\.([^\.]+)$/\.AB\.$1/r,
		"check for original file" );

ok ( -e $test_txt_path =~ s/\.([^\.]+)$/\.AB\.CAB\.srt/r,
		"checking for converted file and abbreviations" );

is ($o{ok}, 0, "number of downloaded");
is ($o{skip}, 1, "number of skipped");
is ($o{conv}, 1, "number of converted");

NapiTest::clean_testspace();
done_testing();


