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

if __name__ == '__main__':
    napi.testcase.runTests()
