#!/usr/bin/python

import os
import re

# integration testing helpers
import napi.cover
import napi.fs
import napi.movie_details
import napi.sandbox
import napi.subtitles
import napi.testcase

class BasicFetchTest(napi.testcase.NapiTestCase):

    def test_ifObtainsAvailableSubtitlesForSingleFile(self):
        """
        Brief:

        This test checks if napi is able to download subtitles for a single
        media files provided directly in the command line.

        Procedure:
        1. Prepare sandbox and media file
        2. Call napi with path to media file

        Expected Results:
        Subtitles file should exist after calling napi.
        """
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            # generate a media file
            media = self.assets.prepareRandomMedia(sandbox)

            # program napiprojekt mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"))

            fs = napi.fs.Filesystem(media)

            # call napi
            self.napiScan(os.path.join(sandbox.path, media['name']))

            # check assertions
            req = self.napiMock.getRequest()
            self.assertEquals(req.method, "POST")
            self.assertEquals(req.url, '/api/api-napiprojekt3.php')
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'napisy pobrano pomyslnie')))

            self.assertTrue(fs.subtitlesExists())
            self.assertFalse(fs.xmlExists())

    def test_ifObtainsAvailableSubtitlesForMediaInDirectory(self):
        """
        Brief:

        Procedure:

        Expected Results:

        """
        mediasAvailable = []
        mediasUnavailable = []
        with napi.sandbox.Sandbox() as sandbox:

            nAvailable = 3
            nUnavailable = 3
            nTotal = nAvailable + nUnavailable

            # prepare responses for available subs
            for _ in xrange(nAvailable):
                media = self.assets.prepareRandomMedia(sandbox)
                mediasAvailable.append(media)

                # program http mock
                self.napiMock.programXmlRequest(
                        media,
                        napi.subtitles.CompressedSubtitles.fromString(
                            media['asset'], "test subtitles"))

            # prepare responses for unavailable subs
            for _ in xrange(nUnavailable):
                media = self.assets.prepareRandomMedia(sandbox)
                mediasUnavailable.append(media)
                self.napiMock.programXmlRequest(media)

            # call napi
            self.napiScan('--stats', sandbox.path)

            # check assertions
            for n in xrange(nTotal):
                req = self.napiMock.getRequest(n)
                self.assertEquals(req.method, "POST")
                self.assertEquals(req.url, '/api/api-napiprojekt3.php')

            # check statistics
            stats = self.output.parseStats()
            self.assertEquals(nAvailable, stats['ok'])
            self.assertEquals(nUnavailable, stats['unav'])
            self.assertEquals(nTotal, stats['total'])

            allMedia = mediasAvailable + mediasUnavailable
            self.assertEqual(nAvailable, sum([ 1 for m in allMedia
                if napi.fs.Filesystem(m).subtitlesExists()]))

    def test_ifDownloadsCoverFilesForSingleMedia(self):
        """
        Brief:

        Procedure:

        Expected Results:

        """
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            # obtain an media
            media = self.assets.prepareRandomMedia(sandbox)

            # program napiprojekt mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    napi.cover.Cover.fromString(
                        media['asset'], "test cover data"))

            # call napi
            self.napiScan("-c", "--stats",
                    os.path.join(sandbox.path, media['name']))

            fs = napi.fs.Filesystem(media)

            # check assertions
            req = self.napiMock.getRequest()
            self.assertEquals(req.method, "POST")
            self.assertEquals(req.url, '/api/api-napiprojekt3.php')

            # check for subs success
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'napisy pobrano pomyslnie')))

            # check for cover success
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'okladka pobrana pomyslnie')))

            # check statistics
            stats = self.output.parseStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['cover_ok'])
            self.assertEquals(1, stats['total'])

            self.assertTrue(fs.subtitlesExists())
            self.assertTrue(fs.coverExists())
            self.assertFalse(fs.xmlExists())

    def test_ifDownloadsNfoFilesForSingleMedia(self):
        """
        Brief:

        Procedure:

        Expected Results:

        """
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            # obtain media file
            media = self.assets.prepareRandomMedia(sandbox)

            # program napiprojekt mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"))

            # call napi
            self.napiScan("-n", "--stats",
                    os.path.join(sandbox.path, media['name']))

            fs = napi.fs.Filesystem(media)

            # check assertions
            req = self.napiMock.getRequest()
            self.assertEquals(req.method, "POST")
            self.assertEquals(req.url, '/api/api-napiprojekt3.php')

            # check for subs success
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'napisy pobrano pomyslnie')))

            # check for cover success
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'plik nfo utworzony pomyslnie')))

            # check statistics
            stats = self.output.parseStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['nfo_ok'])
            self.assertEquals(1, stats['total'])
            self.assertTrue(fs.subtitlesExists())

            self.assertTrue(fs.nfoExists())
            self.assertFalse(fs.xmlExists())

    def test_ifSkipsDownloadingIfSubtitlesAlreadyDownloaded(self):
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
# $output = NapiTest::qx_napi($shell, "--stats -s " . $NapiTest::testspace);
# %output = NapiTest::parse_summary($output);
# is ($output{skip}, $total_available, "Total number of skipped");
# is ($output{skip} + $output{unav}, $output{total}, "Total processed (with skipping)");
# is ($output{total}, $total_available + $total_unavailable, "Total processed (with skipping) 2");
# 

    def test_ifSkipsFilesSmallerThanConfiguredLimit(self):
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
# # Verify if napi works for specified media directory and skips the files smaller than specified (-b option)
# #
# # Preconditions:
# # - napi.sh & subotage.sh must be available in public $PATH
# # - prepare a set of test files and a test directory structure
# #
# # Procedure:
# # - Call napi with the path to the pre-prepared media directory
# # - specify various values for the -b option
# #
# # Expected results:
# # - napi shouldn't download the subtitles for the media files (for which they are available) which are smaller than specified
# #
# NapiTest::clean_testspace();
# prepare_assets();
# 
# # prepare big files
# my $dir_cnt = 0;
# foreach my $dir (glob ($NapiTest::testspace . '/*')) {
# 
# 	my $basepath = $dir . "/test_file";
# 
# 	$basepath =~ s/([\<\>\'\"\$\[\]\@\ \&\#\(\)]){1}/\\$1/g;
# 	# print 'After: ' . $basepath . "\n";
# 
# 	system("dd if=/dev/urandom of=" . $basepath .  $_ . ".avi bs=1M count=" . $_)
# 		foreach(15, 20);
# 	$dir_cnt++;
# }
# 
# $output = NapiTest::qx_napi($shell, "--stats -b 12 " . $NapiTest::testspace);
# %output = NapiTest::parse_summary($output);
# is ($output{unav}, $dir_cnt * 2, "Number of processed files bigger than given size");
# 
# $output = NapiTest::qx_napi($shell, "--stats -b 16 " . $NapiTest::testspace);
# %output = NapiTest::parse_summary($output);
# is ($output{unav}, $dir_cnt, "Number of processed files bigger than given size 2");
# 
# $output = NapiTest::qx_napi($shell, "--stats -b 4 " . $NapiTest::testspace);
# %output = NapiTest::parse_summary($output);
# is ($output{total},
# 	$output{unav} + $output{ok},
# 	"Number of processed files bigger than given size 2");
# 
# NapiTest::clean_testspace();
# done_testing();

if __name__ == '__main__':
    napi.testcase.runTests()
