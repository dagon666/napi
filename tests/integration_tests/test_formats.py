#!/usr/bin/python

import os
import re
import unittest

import napi.fs
import napi.sandbox
import napi.subtitles
import napi.testcase

class FormatsConversionTest(napi.testcase.NapiTestCase):

    def test_ifConvertsToSubripFormat(self):
        """
        Brief: Verify if the conversion to subrip format is being performed
        Procedure:
        Expected Results:
        """
        media = None

        with napi.sandbox.Sandbox() as sandbox:
            # generate a media file
            media = self.videoAssets.prepareRandomMedia(sandbox)
            subs = self.subtitlesAssets.prepareRandomMedia(sandbox, 'subrip')

            # program napiprojekt mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromFile(
                        media['asset'],
                        subs['path']))

            fs = napi.fs.Filesystem(media)

            self.napiScan('-f','subrip',
                    os.path.join(sandbox.path, media['name']))

            # check assertions
            req = self.napiMock.getRequest()
            self.assertEquals(req.method, "POST")
            self.assertEquals(req.url, '/api/api-napiprojekt3.php')
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'napisy pobrano pomyslnie')))

            # confirm the format
            self.assertTrue(fs.subtitlesExists())
            for s in fs.getSubtitlesPaths():
                self.subotageExecute('-gi', '-i', s)
                self.assertTrue(self.output.stdoutContains(
                    re.compile(r'IN_FORMAT -> subrip')))

    @unittest.skip("subotage.sh must be ported first")
    def test_ifConvertsToMicrodvdFormat(self):
        """
        Brief:
        Procedure:
        Expected Results:
        """
        pass

    @unittest.skip("subotage.sh must be ported first")
    def test_ifConvertsToTmplayerFormat(self):
        """
        Brief:
        Procedure:
        Expected Results:
        """
        pass

    @unittest.skip("subotage.sh must be ported first")
    def test_ifConvertsToSubviewer2Format(self):
        """
        Brief:
        Procedure:
        Expected Results:
        """
        pass

    @unittest.skip("subotage.sh must be ported first")
    def test_ifSubotagePerformsCrossFormatConversionCorrectly(self):
        """
        Brief:
        Procedure:
        Expected Results:
        """
        pass

# # microdvd
# NapiTest::qx_napi($shell, " -f microdvd " . $test_file_path);
# ok ( -e $subs_path{orig}, 'checking the original file' );
# ok ( -e $subs_path{txt}, 'checking the converted microdvd file' );
#
# is ( (split ' ', qx/subotage.sh -gi -i $subs_path{txt} | grep IN_FORMAT/)[3],
# 	'microdvd',
# 	'checking if converted format is microdvd'
# );
#
#
# # mpl2
# NapiTest::qx_napi($shell, " -f mpl2 " . $test_file_path);
# ok ( -e $subs_path{orig}, 'checking the original file' );
# ok ( -e $subs_path{txt}, 'checking the converted mpl2 file' );
#
# is ( (split ' ', qx/subotage.sh -gi -i $subs_path{txt} | grep IN_FORMAT/)[3],
# 	'mpl2',
# 	'checking if converted format is mpl2'
# );
#
#
# # tmplayer
# NapiTest::qx_napi($shell, " -f tmplayer " . $test_file_path);
# ok ( -e $subs_path{orig}, 'checking the original file' );
# ok ( -e $subs_path{txt}, 'checking the converted tmplayer file' );
#
# is ( (split ' ', qx/subotage.sh -gi -i $subs_path{txt} | grep IN_FORMAT/)[3],
# 	'tmplayer',
# 	'checking if converted format is tmplayer'
# );
#
#
# # subviewer2
# NapiTest::qx_napi($shell, " -f subviewer2 " . $test_file_path);
# ok ( -e $subs_path{orig}, 'checking the original file' );
# ok ( -e $subs_path{sub}, 'checking the converted subviewer file' );
#
# is ( (split ' ', qx/subotage.sh -gi -i $subs_path{sub} | grep IN_FORMAT/)[3],
# 	'subviewer2',
# 	'checking if converted format is subviewer'
# );


# #
# # all the supported formats
# #
# my @formats = (
# 	'subrip',
# 	'microdvd',
# 	'mpl2',
# 	'tmplayer',
# 	'subviewer2'
# );
#
#
# my @dst_formats=();
# my $cnt = 0;
#
# #>TESTSPEC
# #
# # Brief:
# #
# # Verify if the conversion from each supported format to any other is
# # performed correctly
# #
# # Preconditions:
# # - subotage.sh must be available in public $PATH
# # - prepare subtitles directory containing input files of every supported format
# #
# # Procedure:
# # - Call subotage with given file and requested output format
# # - check if the destination file exists
# # - check if subotage return code doesn't indicate error
# # - check the if the format detect by subotage indicates requested format
# #
# # Expected results:
# # - the converted file should be in format as selected prior to conversion
# #
#
# # iterate through formats
# foreach my $format (@formats) {
#
# 	# strip out current format from processing
# 	@dst_formats = map { $_ ne $format ? $_ : () } @formats;
#
# 	# and through files of given format
# 	foreach my $file (glob ($NapiTest::testspace . '/subtitles/*' . $format . '*')) {
#
# 		# and through destination formats
# 		foreach my $dst_format (@dst_formats) {
#
# 			my $dst_file = $NapiTest::testspace .
# 				"/converted/out_${format}_${dst_format}_${cnt}.txt";
#
# 			my $rv = NapiTest::system_subotage($shell, " -i " . $file .
# 				" -of $dst_format -o $dst_file ");
#
# 			my $minimum = 6;
#
# 			$minimum = 12 if $dst_format eq 'subviewer2';
# 			$minimum = 10 if $dst_format eq 'subrip';
# 			$minimum = 2 if $format eq 'subviewer2';
#
# 			is ($rv, 0, "return value for $format -> $dst_format conversion");
# 			is ( -e $dst_file, 1, "checking $dst_file existence" );
# 			ok ( (count_lines $dst_file) >= $minimum, "the number of lines $dst_file" );
#
# 			# check format detection
# 			is ( (split ' ', qx/subotage.sh -gi -i $dst_file | grep IN_FORMAT/)[3],
# 				$dst_format,
# 				"checking if converted format is $dst_format"
# 			);
#
# 			$cnt++;
# 		}
# 	}
# }



if __name__ == '__main__':
    napi.testcase.runTests()
