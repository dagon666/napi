#!/usr/bin/python

import re

import napi.fs
import napi.sandbox
import napi.subtitles
import napi.testcase

class CharsetConversionTest(napi.testcase.NapiTestCase):

    def _commonCharsetTest(self, charset):
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            media = self.assets.prepareRandomMedia(sandbox)

            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"))

            self.napiScan('--stats', '-C', charset, media['path'])
            stats = self.output.parseNapiStats()

            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(1, stats['conv_charset'])
            self.assertEquals(0, stats['unav'])
            self.assertTrue(napi.fs.Filesystem(media).subtitlesExists())


    def test_ifIconvInvocationIsCorrectForUtf8(self):
        """
        Brief:
        Test if charset conversion to utf8 succeeds for the subtitles file

        Procedure:
        1. Prepare a media file
        2. Program napiprojekt.pl mock to respond with success XmlResponse
        3. Call napi -C utf8

        Expected Results:
        The charset should be successfully converted

        """
        self._commonCharsetTest('utf8')

    def test_ifConvertsToIso88592(self):
        """
        Brief:
        Test if charset conversion to ISO_8859-2 succeeds for the subtitles file

        Procedure:
        1. Prepare a media file
        2. Program napiprojekt.pl mock to respond with success XmlResponse
        3. Call napi -C ISO_8859-2

        Expected Results:
        The charset should be successfully converted

        """
        self._commonCharsetTest('ISO_8859-2')

    def test_ifHandlesConversionFailureCorrectly(self):
        """
        Brief:
        Procedure:
        Expected Results:
        """
        media = None
        charset = 'completely-unsupported-charset-from-space'
        self.isStderrExpected = True

        with napi.sandbox.Sandbox() as sandbox:
            media = self.assets.prepareRandomMedia(sandbox)

            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"))

            self.napiScan('--stats', '-C', charset, media['path'])
            self.assertTrue(self.output.stderrContains(
                re.compile(r'konwersja kodowania niepomyslna')))

            self.assertTrue(napi.fs.Filesystem(media).subtitlesExists())


if __name__ == '__main__':
    napi.testcase.runTests()
