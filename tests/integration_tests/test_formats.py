#!/usr/bin/python

import os
import re
import unittest
import shutil

import napi.fs
import napi.sandbox
import napi.subtitles
import napi.testcase

class FormatsConversionTest(napi.testcase.NapiTestCase):

    def _napiFormatConversion(self, fromFormat, toFormat):
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            # generate a media file
            media = self.videoAssets.prepareRandomMedia(sandbox)
            subs = self.subtitlesAssets.prepareRandomMedia(sandbox,
                    fromFormat)

            # program napiprojekt mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromFile(
                        media['asset'],
                        subs['path']))

            fs = napi.fs.Filesystem(media)

            # get the subs
            self.napiScan('-f', toFormat,
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
                    re.compile(r'IN_FORMAT -> {}'.format(toFormat))))

    def _subotageFormatDetect(self, fmt):
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            # generate a subs file
            subs = self.subtitlesAssets.prepareRandomMedia(sandbox, fmt)
            self.subotageExecute('-gi', '-i', subs['path'])
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'IN_FORMAT -> {}'.format(fmt))))

    def _subotageFormatConversion(self, fromFormat, toFormat):
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            # generate a subs file
            subs = self.subtitlesAssets.prepareRandomMedia(sandbox,
                    fromFormat)

            outputFile = os.path.join(sandbox.path, 'outputfile.txt')

            # ... convert
            self.subotageExecute('-i', subs['path'],
                    '-of', toFormat,
                    '-o', outputFile)

            # if formats match, no conversion happened so, just check if the
            # original file remains unchanged
            if fromFormat == toFormat:
                outputFile = subs['path']

            # ... verify
            self.subotageExecute('-gi', '-i', outputFile)
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'IN_FORMAT -> {}'.format(toFormat))))

    def test_ifSubotageDetectsFormatsCorrectly(self):
        """
        Brief:
        Procedure:
        Expected Results:
        """
        formats = [ 'subrip',   "microdvd", "mpl2",
                "subrip", "subviewer2", "tmplayer" ]
        for fmt in formats:
            self._subotageFormatDetect(fmt)

    def test_ifDownloadsAndConvertsToSubripFormat(self):
        """
        Brief: Verify if the conversion to subrip format is being performed
        Procedure:
        1. Prepare a media asset
        2. Prepare subtitles for the asset
        3. Call napi with a request for media asset and a request for conversion
        4. Verify subs presence
        5. Verify subs format

        Expected Results:
        Subs format should be subrip
        """
        formats = [ 'subrip',   "microdvd", "mpl2",
                "subrip", "subviewer2", "tmplayer" ]
        for fmt in formats:
            self._napiFormatConversion(fmt, 'subrip')

    def test_ifDownloadsAndConvertsToMicrodvdFormat(self):
        """
        Brief: Verify if the conversion to microdvd format is being performed
        Procedure:
        1. Prepare a media asset
        2. Prepare subtitles for the asset
        3. Call napi with a request for media asset and a request for conversion
        4. Verify subs presence
        5. Verify subs format

        Expected Results:
        Subs format should be microdvd
        """
        formats = [ 'subrip',   "microdvd", "mpl2",
                "subrip", "subviewer2", "tmplayer" ]
        for fmt in formats:
            self._napiFormatConversion(fmt, 'microdvd')

    def test_ifDownloadsAndConvertsToTmplayerFormat(self):
        """
        Brief: Verify if the conversion to tmplayer format is being performed
        Procedure:
        1. Prepare a media asset
        2. Prepare subtitles for the asset
        3. Call napi with a request for media asset and a request for conversion
        4. Verify subs presence
        5. Verify subs format

        Expected Results:
        Subs format should be tmplayer
        """
        formats = [ 'subrip',   "microdvd", "mpl2",
                "subrip", "subviewer2", "tmplayer" ]
        for fmt in formats:
            self._napiFormatConversion(fmt, 'tmplayer')

    def test_ifDownloadsAndConvertsToSubviewer2Format(self):
        """
        Brief: Verify if the conversion to subviewer2 format is being performed
        Procedure:
        1. Prepare a media asset
        2. Prepare subtitles for the asset
        3. Call napi with a request for media asset and a request for conversion
        4. Verify subs presence
        5. Verify subs format

        Expected Results:
        Subs format should be subviewer2
        """
        formats = [ 'subrip',   "microdvd", "mpl2",
                "subrip", "subviewer2", "tmplayer" ]
        for fmt in formats:
            self._napiFormatConversion(fmt, 'subviewer2')

    def test_ifDownloadsAndConvertsToMpl2Format(self):
        """
        Brief: Verify if the conversion to mpl2 format is being performed
        Procedure:
        1. Prepare a media asset
        2. Prepare subtitles for the asset
        3. Call napi with a request for media asset and a request for conversion
        4. Verify subs presence
        5. Verify subs format

        Expected Results:
        Subs format should be mpl2
        """
        formats = [ 'subrip',   "microdvd", "mpl2",
                "subrip", "subviewer2", "tmplayer" ]
        for fmt in formats:
            self._napiFormatConversion(fmt, 'mpl2')

    def test_ifConvertsToSubripFormat(self):
        """
        Brief: Verify if the conversion to subrip format is being performed
        Procedure:
        2. Prepare subtitles for the asset
        3. Call subotage with a given subs and desired output format
        4. Verify subs presence
        5. Verify subs format

        Expected Results:
        Subs format should be subrip
        """
        formats = [ 'subrip',   "microdvd", "mpl2",
                "subrip", "subviewer2", "tmplayer" ]
        for fmt in formats:
            self._subotageFormatConversion(fmt, 'subrip')

    def test_ifConvertsToMicrodvdFormat(self):
        """
        Brief: Verify if the conversion to microdvd format is being performed
        Procedure:
        2. Prepare subtitles for the asset
        3. Call subotage with a given subs and desired output format
        4. Verify subs presence
        5. Verify subs format

        Expected Results:
        Subs format should be microdvd
        """
        formats = [ 'subrip',   "microdvd", "mpl2",
                "subrip", "subviewer2", "tmplayer" ]
        for fmt in formats:
            self._subotageFormatConversion(fmt, 'microdvd')

    def test_ifConvertsToTmplayerFormat(self):
        """
        Brief: Verify if the conversion to tmplayer format is being performed
        Procedure:
        2. Prepare subtitles for the asset
        3. Call subotage with a given subs and desired output format
        4. Verify subs presence
        5. Verify subs format

        Expected Results:
        Subs format should be tmplayer
        """
        formats = [ 'subrip',   "microdvd", "mpl2",
                "subrip", "subviewer2", "tmplayer" ]
        for fmt in formats:
            self._subotageFormatConversion(fmt, 'tmplayer')

    def test_ifConvertsToSubviewer2Format(self):
        """
        Brief: Verify if the conversion to subviewer2 format is being performed
        Procedure:
        2. Prepare subtitles for the asset
        3. Call subotage with a given subs and desired output format
        4. Verify subs presence
        5. Verify subs format

        Expected Results:
        Subs format should be subviewer2
        """
        formats = [ 'subrip',   "microdvd", "mpl2",
                "subrip", "subviewer2", "tmplayer" ]
        for fmt in formats:
            self._subotageFormatConversion(fmt, 'subviewer2')

    def test_ifConvertsToMpl2Format(self):
        """
        Brief: Verify if the conversion to mpl2 format is being performed
        Procedure:
        2. Prepare subtitles for the asset
        3. Call subotage with a given subs and desired output format
        4. Verify subs presence
        5. Verify subs format

        Expected Results:
        Subs format should be mpl2
        """
        formats = [ 'subrip',   "microdvd", "mpl2",
                "subrip", "subviewer2", "tmplayer" ]
        for fmt in formats:
            self._subotageFormatConversion(fmt, 'mpl2')

if __name__ == '__main__':
    napi.testcase.runTests()
