#!/usr/bin/python

import re
import unittest

import napi.fs
import napi.sandbox
import napi.subtitles
import napi.testcase

class LegacyApiModeTest(napi.testcase.NapiTestCase):

    def test_ifFailsCorrectlyIfSubsUnavailable(self):
        """
        Brief:
        Verify if handles subs acquisition failure without any errors

        Procedure:
        1. Prepare media file
        2. Program napi mock to respond with no data and 404 HTTP Status
        3. Call napi.sh in legacy mode with id = pynapi

        Expected Results:
        No processing errors should be detected. Normal error response handling
        should be done. No files should be produced afterwards.

        """
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            # generate a media file
            media = self.videoAssets.prepareRandomMedia(sandbox)

            # program napiprojekt mock
            self.napiMock.programPlainRequest()

            # call napi
            self.isStderrExpected = True
            self.napiScan('-i', 'pynapi', media['path'])
            fs = napi.fs.Filesystem(media)

            # check assertions
            req = self.napiMock.getRequest()
            self.assertEquals(req.method, "GET")
            self.assertTrue(re.match(r'/unit_napisy/dl\.php\?', req.url))

            self.assertTrue(self.output.hasErrors())
            self.assertTrue(self.output.stderrContains(
                re.compile(r'nie udalo sie pobrac napisow')))
            self.assertFalse(fs.subtitlesExists())


    def test_ifFailsCorrectlyIfResponseIsTooShort(self):
        """
        Brief: Verify if napi fails responses which are awkwardly short.
        Procedure:
        1. Prepare a media file
        2. Program napi mock to respond with:
        4
        NPc0
        0

        This response most of the time indicates lack of requested subtitles.

        Expected Results:
        No processing errors should be detected. Normal error response handling
        should be done. No files should be produced afterwards.
        """
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            # generate a media file
            media = self.videoAssets.prepareRandomMedia(sandbox)

            # program napiprojekt mock
            self.napiMock.programPlainRequest(
                    napi.subtitles.Subtitles.fromString(
                        media['asset'], '4\nNPc0\n0'))

            # call napi
            self.isStderrExpected = True
            self.napiScan('-i', 'pynapi', media['path'])
            fs = napi.fs.Filesystem(media)

            # check assertions
            req = self.napiMock.getRequest()
            self.assertEquals(req.method, "GET")
            self.assertTrue(re.match(r'/unit_napisy/dl\.php\?', req.url))

            self.assertTrue(self.output.hasErrors())
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'plik uszkodzony. niepoprawna ilosc linii')))
            self.assertFalse(fs.subtitlesExists())


    def test_ifFetchesSingleCompressedFile(self):
        """
        Brief:
        Verify if napi works for single media files in legacy mode (other)

        Procedure:
        1. Prepare subtitles media
        2. Prepare video media
        3. Program napi mock to respond with plain compressed subs HTTP
        response for GET request
        4. Call napi.sh in legacy mode with id = other

        Expected Results:
        napi.sh should perform a GET request to napi.sh using legacy API.
        Subtitles file should exist afterwards.
        """
        media = None
        subsMedia = None
        with napi.sandbox.Sandbox() as sandbox:
            # generate a media file
            media = self.videoAssets.prepareRandomMedia(sandbox)
            subsMedia = self.subtitlesAssets.prepareRandomMedia(sandbox)

            # program napiprojekt mock
            self.napiMock.programPlainRequest(
                    napi.subtitles.CompressedSubtitles.fromFile(
                        media['asset'], subsMedia['path']))

            # call napi
            self.napiScan('-i', 'other', media['path'])
            fs = napi.fs.Filesystem(media)

            # check assertions
            req = self.napiMock.getRequest()
            self.assertEquals(req.method, "GET")
            self.assertTrue(re.match(r'/unit_napisy/dl\.php\?', req.url))

            self.assertTrue(self.output.stdoutContains(
                re.compile(r'napisy pobrano pomyslnie')))

            self.assertTrue(fs.subtitlesExists())

    def test_ifFetchesSingleMediaFile(self):
        """
        Brief:
        Verify if napi works for single media files in legacy mode (pynapi)

        Procedure:
        1. Prepare subtitles media
        2. Prepare video media
        3. Program napi mock to respond with plain subs HTTP response for GET
        request
        4. Call napi.sh in legacy mode with id = pynapi

        Expected Results:
        napi.sh should perform a GET request to napi.sh using legacy API.
        Subtitles file should exist afterwards.
        """
        media = None
        subsMedia = None
        with napi.sandbox.Sandbox() as sandbox:
            # generate a media file
            media = self.videoAssets.prepareRandomMedia(sandbox)
            subsMedia = self.subtitlesAssets.prepareRandomMedia(sandbox)

            # program napiprojekt mock
            self.napiMock.programPlainRequest(
                    napi.subtitles.Subtitles.fromFile(
                        media['asset'], subsMedia['path']))

            # call napi
            self.napiScan('-i', 'pynapi', media['path'])
            fs = napi.fs.Filesystem(media)

            # check assertions
            req = self.napiMock.getRequest()
            self.assertEquals(req.method, "GET")
            self.assertTrue(re.match(r'/unit_napisy/dl\.php\?', req.url))

            self.assertTrue(self.output.stdoutContains(
                re.compile(r'napisy pobrano pomyslnie')))

            self.assertTrue(fs.subtitlesExists())

    def test_ifScanWorksForDirectory(self):
        """
        Brief: Verify if napi works for specified media directory
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
                media = self.videoAssets.prepareRandomMedia(sandbox)
                subsMedia = self.subtitlesAssets.prepareRandomMedia(sandbox)
                mediasAvailable.append(media)

                # program http mock
                self.napiMock.programPlainRequest(
                        napi.subtitles.Subtitles.fromFile(
                            media['asset'], subsMedia['path']))

            # prepare responses for unavailable subs
            for _ in xrange(nUnavailable):
                media = self.videoAssets.prepareRandomMedia(sandbox)
                mediasUnavailable.append(media)
                self.napiMock.programPlainRequest()

            # call napi
            self.isStderrExpected = True
            self.napiScan('--stats', '-i', 'pynapi', sandbox.path)

            # check assertions
            for n in xrange(nTotal):
                req = self.napiMock.getRequest(n)
                self.assertEquals(req.method, "GET")
                self.assertTrue(re.match(r'/unit_napisy/dl\.php\?', req.url))

            # check statistics
            stats = self.output.parseNapiStats()
            self.assertEquals(nAvailable, stats['ok'])
            self.assertEquals(nUnavailable, stats['unav'])
            self.assertEquals(nTotal, stats['total'])

            allMedia = mediasAvailable + mediasUnavailable
            self.assertEqual(nAvailable, sum([ 1 for m in allMedia
                if napi.fs.Filesystem(m).subtitlesExists()]))

    def test_ifSkippingWorks(self):
        """
        Brief:
        This test verifies if napi is skipping the subtitles download for media
        files for which the subtitles file seems to already exist in the
        filesystem.

        Procedure:
        1. Prepare a set of media files.
        2. Program napiprojekt.pl mock to respond with success response.
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
                media = self.videoAssets.prepareRandomMedia(sandbox)
                subsMedia = self.subtitlesAssets.prepareRandomMedia(sandbox)
                medias.append(media)

                # program http mock
                self.napiMock.programPlainRequest(
                        napi.subtitles.CompressedSubtitles.fromFile(
                            media['asset'], subsMedia['path']),
                        200,
                        nAttempts)

            for attempt in xrange(nAttempts):
                # call napi
                self.napiScan('--stats', '-s', '-i', 'pynapi', sandbox.path)

                stats = self.output.parseNapiStats()
                if attempt == 0:
                    for n in xrange(nTotal):
                        req = self.napiMock.getRequest(n + nTotal*attempt)
                        self.assertTrue(req)
                        self.assertEquals(req.method, "GET")
                        self.assertTrue(re.match(r'/unit_napisy/dl\.php\?', req.url))

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

# # Brief:
# #
# # Verify if napi works for specified media directory and skips downloading if the subtitles file already exist
# #
# # Preconditions:
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

if __name__ == '__main__':
    napi.testcase.runTests()
