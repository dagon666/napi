#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(./lib);
use NapiTest;

use Test::More;
use File::Copy;

my $shell = $ENV{NAPI_TEST_SHELL} // "/bin/bash";

# prepare test file
my $test_file = 'video.mp4';
my $test_txt = 'video.txt';
my $test_eng = 'video.eng';

my $test_file_path = $NapiTest::testspace . '/' . $test_file;
my $test_eng_path = $NapiTest::testspace . '/' . $test_eng;
my $test_txt_path = $NapiTest::testspace . '/' . $test_txt;


#>TESTSPEC
#
# Brief:
# 
# Verify if napi correctly downloads subs in different language
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - prepare a media file for which subtitles in english exists
#
# Procedure:
# - Call napi with the -L ENG option 
#
# Expected results:
# - napi should download subs in given language
#
copy $NapiTest::assets . '/eng.mp4', $test_file_path;
NapiTest::qx_napi($shell, " -L ENG -e eng " . $test_file_path);
ok ( -e $test_eng_path,
	'checking if subs file exists');


#>TESTSPEC
#
# Brief:
# 
# Verify the subtitle files are really different
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - prepare a media file for which subtitles in english exists
# - english subtitles in file video.eng
#
# Procedure:
# - Call napi 
# - compare the contents of the video.txt and videol.eng files
#
# Expected results:
# - the files should be different
#
NapiTest::qx_napi($shell, $test_file_path);
ok ( -e $test_txt_path,
	'checking if original subs file exists');

my @diffs = qx/diff $test_eng_path $test_txt_path | wc -l/;
isnt ( scalar @diffs, 0, 'checking if files are different' );


NapiTest::clean_testspace();
done_testing();
