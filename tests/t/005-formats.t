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
my %subs = (
	txt => 'video.txt',
	srt => 'video.srt',
	sub => 'video.sub',
	orig => 'ORIG_video.txt',
);


# create paths
my $test_file_path = $NapiTest::testspace . '/' . $test_file;
my %subs_path = 
	map { ($_, $NapiTest::testspace . '/' . $subs{$_}) }  keys %subs;


#>TESTSPEC
#
# Brief:
# 
# Verify if the conversion to subrip format is being performed
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - prepare a media file for which subtitles in english exists
#
# Procedure:
# - Call napi 
# - check the if the format detect by subotage indicates subrip format
# - check the if the format detect by subotage indicates microdvd format
#
# Expected results:
# - the converted file should be in format as selected prior to conversion
#
copy $NapiTest::assets . '/av1.dat', $test_file_path;
NapiTest::qx_napi($shell, " -f subrip " . $test_file_path);
ok ( -e $subs_path{orig}, 'checking the original file' );
ok ( -e $subs_path{srt}, 'checking the converted subrip file' );

is ( (split ' ', qx/subotage.sh -gi $subs_path{srt}/)[0],
	'subrip',
	'checking if converted format is subrip'
);

# microdvd
NapiTest::qx_napi($shell, " -f microdvd " . $test_file_path);
ok ( -e $subs_path{orig}, 'checking the original file' );
ok ( -e $subs_path{txt}, 'checking the converted microdvd file' );

is ( (split ' ', qx/subotage.sh -gi $subs_path{txt}/)[0],
	'microdvd',
	'checking if converted format is microdvd'
);


# mpl2
NapiTest::qx_napi($shell, " -f mpl2 " . $test_file_path);
ok ( -e $subs_path{orig}, 'checking the original file' );
ok ( -e $subs_path{txt}, 'checking the converted mpl2 file' );

is ( (split ' ', qx/subotage.sh -gi $subs_path{txt}/)[0],
	'mpl2',
	'checking if converted format is mpl2'
);


# tmplayer
NapiTest::qx_napi($shell, " -f tmplayer " . $test_file_path);
ok ( -e $subs_path{orig}, 'checking the original file' );
ok ( -e $subs_path{txt}, 'checking the converted tmplayer file' );

is ( (split ' ', qx/subotage.sh -gi $subs_path{txt}/)[0],
	'tmplayer',
	'checking if converted format is tmplayer'
);


# fab
NapiTest::qx_napi($shell, " -f fab " . $test_file_path);
ok ( -e $subs_path{orig}, 'checking the original file' );
ok ( -e $subs_path{txt}, 'checking the converted fab file' );

is ( (split ' ', qx/subotage.sh -gi $subs_path{txt}/)[0],
	'fab',
	'checking if converted format is fab'
);


# subviewer
NapiTest::qx_napi($shell, " -f subviewer " . $test_file_path);
ok ( -e $subs_path{orig}, 'checking the original file' );
ok ( -e $subs_path{sub}, 'checking the converted subviewer file' );

is ( (split ' ', qx/subotage.sh -gi $subs_path{sub}/)[0],
	'subviewer',
	'checking if converted format is subviewer'
);


NapiTest::clean_testspace();
done_testing();
