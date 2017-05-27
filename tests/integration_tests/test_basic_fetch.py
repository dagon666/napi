#!/usr/bin/python

import os
import re
import sys
import unittest

# integration testing helpers
import napi.assets
import napi.cover
import napi.fs
import napi.mock
import napi.movie_details
import napi.runner
import napi.sandbox
import napi.subtitles

class BasicFetchTest(unittest.TestCase):
    SHELL = "/bin/bash"

    def setUp(self):
        self.napiMock = napi.mock.NapiprojektMock()
        self.napiprojektUrl = self.napiMock.getUrl()

        self.runner = napi.runner.Runner(self.napiprojektUrl, self.SHELL)
        self.assetsPath = os.path.join(
                os.environ.get('NAPICLIENT_TESTDATA', '/opt/napi/testdata'),
                'testdata',
                'media')
        self.assets = napi.assets.Assets(self.assetsPath)

        # should be used to store the napi output
        self.output = None

    def tearDown(self):
        if self.output and self.output.hasErrors():
            self.output.printStdout()
            self.output.printStderr()

    def test_ifObtainsAvailableSubtitlesForSingleFile(self):
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
            self.output = self.runner.scan(
                    os.path.join(sandbox.path, media['name']))

            # check assertions
            req = self.napiMock.getRequest()
            self.assertEquals(req.method, "POST")
            self.assertEquals(req.url, '/api/api-napiprojekt3.php')
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'napisy pobrano pomyslnie')))

            self.assertTrue(fs.subtitlesExists())
            self.assertFalse(fs.xmlExists())

    def test_ifObtainsAvailableSubtitlesForMediaInDirectory(self):
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
            self.output = self.runner.scan('--stats', sandbox.path)

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
            self.output = self.runner.scan("-c", "--stats",
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

if __name__ == '__main__':

    # inject shell
    if len(sys.argv) > 1:
        BasicFetchTest.SHELL = sys.argv.pop()

    # run unit tests
    unittest.main()
