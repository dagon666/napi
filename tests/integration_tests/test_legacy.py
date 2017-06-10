#!/usr/bin/python

import re
import unittest

import napi.fs
import napi.sandbox
import napi.subtitles
import napi.testcase

class LegacyApiModeTest(napi.testcase.NapiTestCase):
    def test_if(self):
        """
        Brief:
        Procedure:
        Expected Results:
        """
        pass


# #>TESTSPEC
# #
# # Brief:
# #
# # Verify if napi works for single media files in legacy mode
# #
# # Preconditions:
# # - napi.sh & subotage.sh must be available in public $PATH
# # - prepare a set of test files (one available one unavailable)
# #
# # Procedure:
# # - For each prepared file call napi with it, and check if the script successfully processed it
# #
# # Expected results:
# # - napi should download the subtitles for a file for which the're available and don't download
# # for a testfile for which they for sure don't exist
# #
# # - subtitles files should be created afterwards
# #
#
# # check with a single files
# my @files = (
# 		{
# 			src => 'av1.dat',
# 			dst  => 'available.avi',
# 			res => 'available.txt',
# 			pattern => 'OK',
# 		},
#
# 		{
# 			src => 'unav1.dat',
# 			dst => 'unavailable.avi',
# 			res => 0,
# 			pattern => 'UNAV',
# 	   	},
# );
#
#
# foreach (@files) {
# 	copy $NapiTest::assets . '/' . $_->{src},
# 		 $NapiTest::testspace . '/' . $_->{dst};
#
# 	my $filename = $NapiTest::testspace . '/' . $_->{dst};
# 	my $subs = $NapiTest::testspace . '/' . $_->{res};
#
# 	like ( scalar NapiTest::qx_napi($shell, " --id pynapi " . $filename),
# 			qr/#\d+:\d+\s$_->{pattern}\s->\s/,
# 			"Single File ($_->{dst}) test");
#
# 	is (-e $subs ? 1 : 0,
# 			$_->{res} ? 1 : 0,
# 			"Subtitles file ($_->{res}) presence test");
#
# 	unlink $NapiTest::testspace . '/' . $_->{dst};
# 	unlink $NapiTest::testspace . '/' . $_->{res} if $_->{res};
# }
#
# #
# #>TESTSPEC
# #
# # Brief:
# #
# # Verify if napi works for specified media directory
# #
# # Preconditions:
# # - napi.sh & subotage.sh must be available in public $PATH
# # - prepare a set of test files and a test directory structure
# #
# # Procedure:
# # - Call napi with the path to the pre-prepared media directory
# #
# # Expected results:
# # - napi should download the subtitles for all files (for which they are available) and should
# # traverse the whole directory tree - in search for media files
# #
# # - the processing results must be reflected in the napi summary correctly
# #
# prepare_assets();
#
# my %output = ();
# my $output = NapiTest::qx_napi($shell, " --id pynapi --stats " . $NapiTest::testspace);
#
# %output = NapiTest::parse_summary($output);
# is ($output{ok}, $total_available, "Total number downloaded");
# is ($output{unav}, $total_unavailable, "Total number of unavailable");
# is ($output{ok} + $output{unav}, $output{total}, "Total processed");
# is ($output{total}, $total_available + $total_unavailable, "Total processed 2");
#
#
# #>TESTSPEC
# #
# # Brief:
# #
# # Verify if napi works for specified media directory and skips downloading if the subtitles file already exist
# #
# # Preconditions:
# # - napi.sh & subotage.sh must be available in public $PATH
# # - prepare a set of test files and a test directory structure
# # - the subtitles files should exist as well
# #
# # Procedure:
# # - Call napi with the path to the pre-prepared media directory
# #
# # Expected results:
# # - napi shouldn't download the subtitles for the media files (for which they are available) if it detects that the
# # subtitles file already exist
# #
# $output = NapiTest::qx_napi($shell, " --id pynapi --stats -s " . $NapiTest::testspace);
# %output = NapiTest::parse_summary($output);
# is ($output{skip}, $total_available, "Total number of skipped");
# is ($output{skip} + $output{unav}, $output{total}, "Total processed (with skipping)");
# is ($output{total}, $total_available + $total_unavailable, "Total processed (with skipping) 2");
#

if __name__ == '__main__':
    napi.testcase.runTests()
