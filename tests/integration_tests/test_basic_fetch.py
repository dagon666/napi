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
        This test checks if napi is able to scan a directory containing media
        files, detect the presence of media files and obtain subtitles for each
        of them.

        Procedure:
        1. Prepare sandbox and media files with random names
        2. Program napiprojekt mock to reply with success for some of the media
        files and failure for the others.
        3. Call napi with the path to the sandbox

        Expected Results:
        Napi should successfully download subtitles for media files for which
        napiprojekt mock has been programmed to return a successful result.

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
        This test verifies if napi is able to obtain the cover file for media

        Procedure:
        1. Prepare a sandbox with a media file
        2. Program napiprojekt mock to return some test cover data
        3. Call napi with -c parameter

        Expected Results:
        Napi should obtain both the subtitles and the cover file for the media
        file.

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
        This test verifies if napi is able to collect movie information from
        Xml file and collate it into the nfo file.

        Procedure:
        1. Prepare a sandbox with a media file
        2. Program napiprojekt mock to return some test cover data
        3. Call napi with -n parameter

        Expected Results:
        napi should obtain both the subtitles and create an nfo file

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
        This test verifies if napi is skipping the subtitles download for media
        files for which the subtitles file seems to already exist in the
        filesystem.

        Procedure:
        1. Prepare a set of media files.
        2. Program napiprojekt.pl mock to respond with success Xml response.
        3. Call napi -s.
        4. Call napi -s again.

        Expected Results:
        Check if it skipped the download for media files for which subtitles
        have been already obtained.

        """
        medias = []
        with napi.sandbox.Sandbox() as sandbox:

            nTotal = 4
            nAttempts = 3

            # prepare responses for available subs
            for _ in xrange(nTotal):
                media = self.assets.prepareRandomMedia(sandbox)
                medias.append(media)

                # program http mock
                self.napiMock.programXmlRequest(
                        media,
                        napi.subtitles.CompressedSubtitles.fromString(
                            media['asset'], "test subtitles"),
                        None,
                        None,
                        nAttempts)

            for attempt in xrange(nAttempts):
                # call napi
                self.napiScan('--stats', '-s', sandbox.path)

                stats = self.output.parseStats()
                if attempt == 0:
                    for n in xrange(nTotal):
                        req = self.napiMock.getRequest(n + nTotal*attempt)
                        self.assertTrue(req)
                        self.assertEquals(req.method, "POST")
                        self.assertEquals(req.url, '/api/api-napiprojekt3.php')

                    # check statistics
                    self.assertEquals(nTotal, stats['ok'])
                    self.assertEquals(0, stats['skip'])
                    self.assertEquals(0, stats['unav'])
                    self.assertEquals(nTotal, stats['total'])
                else:
                    for n in xrange(nTotal):
                        req = self.napiMock.getRequest(n + nTotal*attempt)
                        self.assertFalse(req)

                    # check statistics
                    self.assertEquals(0, stats['ok'])
                    self.assertEquals(nTotal, stats['skip'])
                    self.assertEquals(0, stats['unav'])
                    self.assertEquals(nTotal, stats['total'])

                self.assertEqual(nTotal, sum([ 1 for m in medias
                    if napi.fs.Filesystem(m).subtitlesExists()]))

    def test_ifSkipsFilesSmallerThanConfiguredLimit(self):
        """
        Brief:
        Verify if napi works for specified media directory and skips the files
        smaller than specified (-b option)

        Procedure:
        1. Prepare some media files with size above and below assumed limit.
        2. Program napiprojekt.pl mock with success Xml response.
        3. Call napi with -b and selected assumed size limit.

        Expected Results:
        napi shouldn't download the subtitles for the media files (for which
        they are available) which are smaller than specified.

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
