#!/usr/bin/python

import os
import re
import sys
import unittest

# integration testing helpers
import napi.assets
import napi.cover
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
        self.output = None

    def tearDown(self):
        if self.output and self.output.hasErrors():
            self.output.printStdout()
            self.output.printStderr()

    def test_ifObtainsAvailableSubtitlesForSingleFile(self):
        asset = None
        with napi.sandbox.Sandbox() as sandbox:
            # obtain an asset
            asset = self.assets.prepareRandomMedia(sandbox)

            # program napiprojekt mock
            self.napiMock.programXmlRequest(
                    napi.subtitles.CompressedSubtitles.fromString(
                        asset['media'], "test subtitles"))

            # call napi
            self.output = self.runner.scan(
                    os.path.join(sandbox.path, asset['name']))

            # check assertions
            req = self.napiMock.getRequest()
            self.assertEquals(req.method, "POST")
            self.assertEquals(req.url, '/api/api-napiprojekt3.php')
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'napisy pobrano pomyslnie')))

    def test_ifObtainsAvailableSubtitlesForMediaInDirectory(self):
        assets = []
        with napi.sandbox.Sandbox() as sandbox:

            nAvailable = 3
            nUnavailable = 3
            nTotal = nAvailable + nUnavailable

            # prepare responses for available subs
            for _ in xrange(nAvailable):
                asset = self.assets.prepareRandomMedia(sandbox)
                assets.append(asset)

                # program http mock
                self.napiMock.programXmlRequest(
                        napi.subtitles.CompressedSubtitles.fromString(
                            asset['media'], "test subtitles"))

            # prepare responses for unavailable subs
            for _ in xrange(nUnavailable):
                asset = self.assets.prepareRandomMedia(sandbox)
                assets.append(asset)
                self.napiMock.programXmlRequest()

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

    def test_ifDownloadsCoverFilesForSingleMedia(self):
        asset = None
        with napi.sandbox.Sandbox() as sandbox:
            # obtain an asset
            asset = self.assets.prepareRandomMedia(sandbox)

            # program napiprojekt mock
            self.napiMock.programXmlRequest(
                    napi.subtitles.CompressedSubtitles.fromString(
                        asset['media'], "test subtitles"),
                    napi.cover.Cover.fromString(
                        asset['media'], "test cover data"))

            # call napi
            self.output = self.runner.scan("-c", "--stats",
                    os.path.join(sandbox.path, asset['name']))

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

if __name__ == '__main__':

    # inject shell
    if len(sys.argv) > 1:
        BasicFetchTest.SHELL = sys.argv.pop()

    # run unit tests
    unittest.main()
