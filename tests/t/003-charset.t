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


#>TESTSPEC
#
# Brief:
# 
# Verify if napi correctly invokes iconv binary (with UTF8 conversion request) for each downloaded subtitles file
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - iconv should be available in the path
# - prepare a media file for which subtitles exist
#
# Procedure:
# - Call napi with the -C option and specified utf8 charset
#
# Expected results:
# - napi should convert the charset to the requested one
#

copy $NapiTest::assets . '/av1.dat', $test_file_path;

NapiTest::qx_napi($shell, " -C utf8 " . $test_file_path);
like(`file -b $test_txt_path`, 
		qr/UTF-8/, "Checking conversion result for UTF-8");


#>TESTSPEC
#
# Brief:
# 
# Verify if napi correctly invokes iconv binary (with iso-8859-2 conversion request) for each downloaded subtitles file
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - iconv should be available in the path
# - prepare a media file for which subtitles exist
#
# Procedure:
# - Call napi with the -C option and specified iso8859-2 charset
#
# Expected results:
# - napi should convert the charset to the requested one
#

NapiTest::qx_napi($shell, " -C ISO_8859-2 " . $test_file_path);
like(`file -b $test_txt_path`, 
		qr/ISO-8859/, "Checking conversion result for ISO");


#>TESTSPEC
#
# Brief:
# 
# Verify if napi performs file processing if skip option has been specified
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - iconv should be available in the path
# - prepare a media file for which subtitles exist
# - subtitles file should already exist for the media file (with known charset) on the fs
#
# Procedure:
# - Call napi with any charset different than the one in which the subtitles file is encoded
#
# Expected results:
# - napi should overwrite already existing file, the charset should be converted
#

NapiTest::qx_napi($shell, " -s -C utf8 " . $test_file_path);
like(`file -b $test_txt_path`, 
		qr/UTF-8/, "Checking conversion result for ISO with skip option");

NapiTest::clean_testspace();
done_testing();
