#!/usr/bin/env perl

use strict;
use warnings;

use lib qw(./lib);
use NapiTest;

use Test::More;
use File::Copy;

NapiTest::clean_testspace();
NapiTest::prepare_fs();

my $shell = $ENV{NAPI_TEST_SHELL} // "/bin/bash";

my $total_available = 0;
my $total_unavailable = 0;

#
#>TESTSPEC
#
# Brief:
#
# Verify if napi downloads covers and nfo files
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - prepare a test file for which a cover exists
#
# Procedure:
# - Call napi with the path to the pre-prepared media file
#
# Expected results:
# - napi should download the cover and the nfo file for the media
# - the processing results must be reflected in the napi summary correctly
#

copy $NapiTest::assets . '/av1.dat', $NapiTest::testspace . '/available.avi';

my %output = ();
my $output = NapiTest::qx_napi($shell, " -c -n --stats " . $NapiTest::testspace . "/available.avi");
%output = NapiTest::parse_summary($output);

is ($output{cover_ok}, 1, "Total covers downloaded");
is ($output{total}, 1, "Total processed");
is (-e $NapiTest::testspace . "/available.jpg", 1, "cover existence");
is (-e $NapiTest::testspace . "/available.nfo", 1, "nfo existence");

#>TESTSPEC
#
# Brief:
#
# Verify if napi works for specified media directory and skips downloading if the subtitles file already exist
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - prepare a set of test files and a test directory structure
# - the subtitles files should exist as well
#
# Procedure:
# - Call napi with the path to the pre-prepared media directory
#
# Expected results:
# - napi shouldn't download the subtitles for the media files (for which they are available) if it detects that the
# subtitles file already exist
#
$output = NapiTest::qx_napi($shell, "--stats -s " . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{skip}, $total_available, "Total number of skipped");
is ($output{skip} + $output{unav}, $output{total}, "Total processed (with skipping)");
is ($output{total}, $total_available + $total_unavailable, "Total processed (with skipping) 2");


#>TESTSPEC
#
# Brief:
#
# Verify if napi works for specified media directory and skips the files smaller than specified (-b option)
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - prepare a set of test files and a test directory structure
#
# Procedure:
# - Call napi with the path to the pre-prepared media directory
# - specify various values for the -b option
#
# Expected results:
# - napi shouldn't download the subtitles for the media files (for which they are available) which are smaller than specified
#
NapiTest::clean_testspace();
prepare_assets();

# prepare big files
my $dir_cnt = 0;
foreach my $dir (glob ($NapiTest::testspace . '/*')) {

	my $basepath = $dir . "/test_file";

	$basepath =~ s/([\<\>\'\"\$\[\]\@\ \&\#\(\)]){1}/\\$1/g;
	# print 'After: ' . $basepath . "\n";

	system("dd if=/dev/urandom of=" . $basepath .  $_ . ".avi bs=1M count=" . $_)
		foreach(15, 20);
	$dir_cnt++;
}

$output = NapiTest::qx_napi($shell, "--stats -b 12 " . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{unav}, $dir_cnt * 2, "Number of processed files bigger than given size");

$output = NapiTest::qx_napi($shell, "--stats -b 16 " . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{unav}, $dir_cnt, "Number of processed files bigger than given size 2");

$output = NapiTest::qx_napi($shell, "--stats -b 4 " . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{total},
	$output{unav} + $output{ok},
	"Number of processed files bigger than given size 2");

NapiTest::clean_testspace();
done_testing();
