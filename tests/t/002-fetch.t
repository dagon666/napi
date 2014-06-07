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


sub prepare_assets {
	foreach my $dir (glob ($NapiTest::testspace . '/*')) {
		
		unless ($dir =~ /unavailable/ ) {
			copy $NapiTest::assets . "/av$_.dat", $dir . "/vid$_.avi"
				foreach(1..3);
			$total_available += 3;
		}
		else {
			copy $NapiTest::assets . "/unav1.dat", $dir . "/vid$_.avi"
				foreach(1..3);
			$total_unavailable += 3;
		}
	}
}


#>TESTSPEC
#
# Brief:
# 
# Verify if napi works for single media files
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - prepare a set of test files (one available one unavailable)
#
# Procedure:
# - For each prepared file call napi with it, and check if the script successfully processed it
#
# Expected results:
# - napi should download the subtitles for a file for which the're available and don't download 
# for a testfile for which they for sure don't exist
#
# - subtitles files should be created afterwards
#

# check with a single files
my @files = (
		{ 
			src => 'av1.dat',
			dst  => 'available.avi',
			res => 'available.txt',
			pattern => 'OK',
		},

		{ 
			src => 'unav1.dat',
			dst => 'unavailable.avi',
			res => 0,
			pattern => 'UNAV',
	   	},
);


foreach (@files) {
	copy $NapiTest::assets . '/' . $_->{src},
		 $NapiTest::testspace . '/' . $_->{dst};

	my $filename = $NapiTest::testspace . '/' . $_->{dst};
	my $subs = $NapiTest::testspace . '/' . $_->{res};

	like ( scalar NapiTest::qx_napi($shell, $filename),
			qr/\[$_->{pattern}\]/,
			"Single File ($_->{dst}) test");

	is (-e $subs ? 1 : 0, 
			$_->{res} ? 1 : 0, 
			"Subtitles file ($_->{res}) presence test");

	unlink $NapiTest::testspace . '/' . $_->{dst};
	unlink $NapiTest::testspace . '/' . $_->{res} if $_->{res};
}


#>TESTSPEC
#
# Brief:
# 
# Verify if napi works for specified media directory
#
# Preconditions:
# - napi.sh & subotage.sh must be available in public $PATH
# - prepare a set of test files and a test directory structure
#
# Procedure:
# - Call napi with the path to the pre-prepared media directory
#
# Expected results:
# - napi should download the subtitles for all files (for which they are available) and should
# traverse the whole directory tree - in search for media files
#
# - the processing results must be reflected in the napi summary correctly
#
prepare_assets();

my %output = ();
my $output = NapiTest::qx_napi($shell, $NapiTest::testspace);

%output = NapiTest::parse_summary($output);
is ($output{pobrano}, $total_available, "Total number downloaded");
is ($output{niedostepne}, $total_unavailable, "Total number of unavailable");
is ($output{pobrano} + $output{niedostepne}, $output{lacznie}, "Total processed");
is ($output{lacznie}, $total_available + $total_unavailable, "Total processed 2");


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
$output = NapiTest::qx_napi($shell, "-s " . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{pominieto}, $total_available, "Total number of skipped");
is ($output{pominieto} + $output{niedostepne}, $output{lacznie}, "Total processed (with skipping)");
is ($output{lacznie}, $total_available + $total_unavailable, "Total processed (with skipping) 2");


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

$output = NapiTest::qx_napi($shell, "-b 12" . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{niedostepne}, $dir_cnt * 2, "Number of processed files bigger than given size");

$output = NapiTest::qx_napi($shell, "-b 16" . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{niedostepne}, $dir_cnt, "Number of processed files bigger than given size 2");

$output = NapiTest::qx_napi($shell, "-b 4" . $NapiTest::testspace);
%output = NapiTest::parse_summary($output);
is ($output{lacznie},
	$output{niedostepne} + $output{pobrano}, 
	"Number of processed files bigger than given size 2");

NapiTest::clean_testspace();
done_testing();
