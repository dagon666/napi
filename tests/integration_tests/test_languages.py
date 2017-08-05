#!/usr/bin/python

import re

import napi.fs
import napi.sandbox
import napi.subtitles
import napi.testcase

class LanguagesTest(napi.testcase.NapiTestCase):

    def _makeLanguageDebugRegex(self, lang):
        return re.compile(r'jezyk skonfigurowany jako [{}]'.format(lang))

    def test_ifDownloadsSubtitlesInDifferentLanguages(self):
        """
        Brief:
        Check if downloads subtitles in different languages without
        errors.

        Procedure:
        1. Prepare a media file
        2. Program napiprojekt mock
        3. Call napi with -L ENG

        Expected Results:
        Check if downloads subtitles file and doesn't generate errors on
        output.
        """
        media = None
        lang = 'ENG'

        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)

            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"))

            self.napiScan('--stats', '-L', lang, media['path'])
            self.output.stdoutContains(self._makeLanguageDebugRegex(lang))

            stats = self.output.parseNapiStats()

            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['conv_charset'])
            self.assertEquals(0, stats['unav'])

            self.assertTrue(
                napi.fs.Filesystem(media).subtitlesExists())

    def test_ifUsesProvidedExtension(self):
        """
        Brief:
        Request subtitles in different language and specify an extension
        for the resulting file.

        Procedure:
        1. Prepare a media file
        2. Program napiprojekt mock
        3. Call napi with -L ENG -e eng

        Expected Results:
        Should download a file successfully and its resulting name should
        be ended with provided extension.
        """
        media = None
        lang = 'ENG'
        ext = lang.lower()

        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)

            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"))

            self.napiScan('--stats', '-L', lang, '-e', ext, media['path'])
            self.output.stdoutContains(self._makeLanguageDebugRegex(lang))

            stats = self.output.parseNapiStats()

            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['conv_charset'])
            self.assertEquals(0, stats['unav'])

            self.assertTrue(
                    napi.fs.Filesystem(media).subtitlesExists(None, ext))

    def test_ifUsesProvidedAbbreviation(self):
        """
        Brief:
        Request subtitles in different language and specify an
        abbreviation for the resulting file.

        Procedure:
        1. Prepare a media file
        2. Program napiprojekt mock
        3. Call napi with -L ENG -a eng

        Expected Results:
        Should download a file successfully and its resulting name should
        contain the string provided as abbreviation, placed in between
        the file name and the extension.
        """
        media = None
        lang = 'ENG'
        abbrev = lang.lower()

        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)

            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"))

            self.napiScan('--stats', '-L', lang, '-a', abbrev, media['path'])
            self.output.stdoutContains(self._makeLanguageDebugRegex(lang))

            stats = self.output.parseNapiStats()

            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['conv_charset'])
            self.assertEquals(0, stats['unav'])

            self.assertTrue(
                    napi.fs.Filesystem(media).subtitlesExists(None, None, abbrev))

    def test_ifUsesProvidedAbbreviationAndExtension(self):
        """
        Brief:
        Request subtitles in different language and specify an
        abbreviation and the extension for the resulting file.

        Procedure:
        1. Prepare a media file
        2. Program napiprojekt mock
        3. Call napi with -L ENG -a eng -e test-extension

        Expected Results:
        Should download a file successfully and its resulting name should
        contain the string provided as abbreviation, placed in between
        the file name and the provided extension.
        """
        media = None
        lang = 'ENG'
        abbrev = lang.lower()
        ext = "test-extension"

        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)

            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"))

            self.napiScan('--stats', '-L', lang,
                    '-a', abbrev,
                    '-e', ext,
                    media['path'])

            self.output.stdoutContains(self._makeLanguageDebugRegex(lang))

            stats = self.output.parseNapiStats()

            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['conv_charset'])
            self.assertEquals(0, stats['unav'])

            self.assertTrue(
                    napi.fs.Filesystem(media).subtitlesExists(None, ext, abbrev))

if __name__ == '__main__':
    napi.testcase.runTests()
