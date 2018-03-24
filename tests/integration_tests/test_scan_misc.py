#!/usr/bin/python

import os
import re
import unittest
import subprocess

import napi.cover
import napi.fs
import napi.sandbox
import napi.subtitles
import napi.testcase
import napi.scpmocker

class ScanActionMiscTest(napi.testcase.NapiTestCase):

    def test_ifUsesProvidedExtension(self):
        """
        Brief:
        Request subtitles and specify an extension for the resulting file.

        Procedure:
        1. Prepare a media file
        2. Program napiprojekt mock
        3. Call napi -e fancy_extension

        Expected Results:
        Should download a file successfully and its resulting name should
        be ended with provided extension.
        """
        media = None
        ext = 'fancy_extension'

        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)

            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"))

            self.napiScan('--stats', '-e', ext, media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            self.assertTrue(
                    napi.fs.Filesystem(media).subtitlesExists(None, ext))

    def test_ifSkippingWorks(self):
        """
        Brief:
        Verify if skipping option works.

        Procedure:
        1. Prepare a media file.
        2. Program napiprojekt.pl mock
        3. Call napi with a path to media to obtain the subtitles
        4. Call napi again with option -s

        Expected Results:
        Napi should not attempt to download the subtitles the second as they
        already exist and the request to skip existing files has been done.
        """
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)
            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    None,
                    None,
                    1)

            self.napiScan('--stats', media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            napiFs = napi.fs.Filesystem(media)
            self.assertTrue(napiFs.subtitlesExists())

            subsPaths = napiFs.getSubtitlesPaths()
            self.assertEquals(1, len(subsPaths))

            # hashed file - to be able to track file content modifications
            subtitles = napi.fs.HashedFile(subsPaths[0])

            self.napiScan('--stats', '-s', media['path'])
            stats = self.output.parseNapiStats()

            self.assertEquals(0, stats['ok'])
            self.assertEquals(1, stats['skip'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            # make sure the original content has not been modified
            self.assertFalse(subtitles.hasChanged())

    def test_ifSkippingWorksWithCustomExtension(self):
        """
        Brief:
        Verify if skipping option works.

        Procedure:
        1. Prepare a media file.
        2. Program napiprojekt.pl mock
        3. Call napi with a path to media to obtain the subtitles
        4. Call napi again with option -s

        Expected Results:
        Napi should not attempt to download the subtitles the second as they
        already exist and the request to skip existing files has been done.
        """
        media = None
        ext = "fancy-extension"
        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)
            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    None,
                    None,
                    1)

            self.napiScan('--stats', '-e', ext, media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            napiFs = napi.fs.Filesystem(media)
            self.assertTrue(napiFs.subtitlesExists(None, ext))

            subsPaths = napiFs.getSubtitlesPaths(None, ext)
            self.assertEquals(1, len(subsPaths))

            # hashed file - to be able to track file content modifications
            subtitles = napi.fs.HashedFile(subsPaths[0])

            self.napiScan('--stats', '-s', '-e', ext, media['path'])
            stats = self.output.parseNapiStats()

            self.assertEquals(0, stats['ok'])
            self.assertEquals(1, stats['skip'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            # make sure the original content has not been modified
            self.assertFalse(subtitles.hasChanged())

    def test_ifSkippingWorksWithCustomExtensionAndAbbreviation(self):
        """
        Brief:
        Verify if skipping option works.

        Procedure:
        1. Prepare a media file.
        2. Program napiprojekt.pl mock
        3. Call napi with a path to media to obtain the subtitles
        4. Call napi again with option -s

        Expected Results:
        Napi should not attempt to download the subtitles the second as they
        already exist and the request to skip existing files has been done.
        """
        media = None
        ext = "fancy-extension"
        abbrev = "abbreviation"
        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)
            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    None,
                    None,
                    1)

            self.napiScan('--stats', '-e', ext,
                    '-a', abbrev, media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            napiFs = napi.fs.Filesystem(media)
            self.assertTrue(napiFs.subtitlesExists(None, ext, abbrev))

            subsPaths = napiFs.getSubtitlesPaths(None, ext, abbrev)
            self.assertEquals(1, len(subsPaths))

            # hashed file - to be able to track file content modifications
            subtitles = napi.fs.HashedFile(subsPaths[0])

            self.napiScan('--stats', '-s', '-e', ext,
                    '-a', abbrev, media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(0, stats['ok'])
            self.assertEquals(1, stats['skip'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            # make sure the original content has not been modified
            self.assertFalse(subtitles.hasChanged())

    def test_ifCopiesExistingSubtitlesToNameWithAbbreviation(self):
        """
        Brief:
        Verify skipping with abbreviation specified

        Procedure:
        1. Prepare media
        2. Program napiprojekt.pl mock
        3. Call napi to obtain the subs
        4. Call napi -a <abbrev> --conv-abbrev <conv-abbrev> -s

        Expected Results:
        1. Subtitles shouldn't be downloaded twice.
        2. Existing subtitles should be copied to the new filename (containing
        abbrev).

        """
        media = None
        ext = "fancy-extension"
        abbrev = "abbreviation"
        convAbbrev = "CAB"
        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)
            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    None,
                    None,
                    1)

            self.napiScan('--stats', '-e', ext, media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            napiFs = napi.fs.Filesystem(media)
            self.assertTrue(napiFs.subtitlesExists(None, ext, abbrev, convAbbrev))

            # check number of subs files, just to be sure that there's only one
            subsPaths = napiFs.getSubtitlesPaths(None, ext,
                    abbrev, convAbbrev)
            self.assertEquals(1, len(subsPaths))

            self.napiScan('--stats', '-s', '-e', ext,
                    '-a',
                    abbrev,
                    '--conv-abbrev',
                    convAbbrev,
                    media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(0, stats['ok'])
            self.assertEquals(1, stats['skip'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            # check again, number of subs
            subsPaths = napiFs.getSubtitlesPaths(None, ext,
                    abbrev, convAbbrev)
            self.assertEquals(2, len(subsPaths))

            # make sure we've got the file with abbrev, not conv-abbrev
            self.assertTrue(any([ True for p in subsPaths
                if re.search(abbrev, p) ]))

            # verify that we've got a copy with abbreviation in the name
            hashedFiles = [ napi.fs.HashedFile(p) for p in subsPaths ]
            self.assertEquals(hashedFiles[0], hashedFiles[1])

    def test_ifMovesExistingSubtitlesWhenMFlagIsGiven(self):
        """
        Brief:
        Verify skipping with abbreviation specified

        Procedure:
        1. Prepare media
        2. Program napiprojekt.pl mock
        3. Call napi to obtain the subs
        4. Call napi -a <abbrev> --conv-abbrev <conv-abbrev> -s -M

        Expected Results:
        1. Subtitles shouldn't be downloaded twice.
        2. Existing subtitles should be MOVED to the new filename (containing
        abbrev).

        """
        media = None
        ext = "fancy-extension"
        abbrev = "abbreviation"
        convAbbrev = "CAB"
        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)
            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    None,
                    None,
                    1)

            self.napiScan('--stats', '-e', ext, media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            napiFs = napi.fs.Filesystem(media)
            self.assertTrue(napiFs.subtitlesExists(None, ext, abbrev, convAbbrev))

            # check number of subs files, just to be sure that there's only one
            subsPaths = napiFs.getSubtitlesPaths(None, ext,
                    abbrev, convAbbrev)
            self.assertEquals(1, len(subsPaths))

            origSubs = napi.fs.HashedFile(subsPaths[0])

            self.napiScan('--stats', '-s', '-e', ext,
                    '-a',
                    abbrev,
                    '--conv-abbrev',
                    convAbbrev,
                    '-M',
                    media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(0, stats['ok'])
            self.assertEquals(1, stats['skip'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            # check again, number of subs
            subsPaths = napiFs.getSubtitlesPaths(None, ext,
                    abbrev, convAbbrev)
            self.assertEquals(1, len(subsPaths))

            # make sure we've got the file with abbrev, not conv-abbrev
            self.assertTrue(re.search(abbrev, subsPaths[0]))

            movedSubs = napi.fs.HashedFile(subsPaths[0])
            self.assertEquals(origSubs, movedSubs)

    def test_ifSkippingWorksForNfoFiles(self):
        """
        Brief:
        Check nfo file skipping

        Procedure:
        1. Prepare a media file.
        2. Program napiprojekt.pl mock
        3. Call napi with a path to media to obtain the subtitles
        4. Call napi again with option -s -n

        Expected Results:
        1. The nfo file should be downloaded.
        2. Subsequent call shouldn't download new nfo, which should be
        resembled in the stats.
        """
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)
            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    None,
                    None,
                    1)

            self.napiScan('--stats', '-n', '-s', media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['nfo_ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            napiFs = napi.fs.Filesystem(media)
            self.assertTrue(napiFs.subtitlesExists())
            self.assertTrue(napiFs.nfoExists())

            subsPaths = napiFs.getSubtitlesPaths()
            self.assertEquals(1, len(subsPaths))

            self.napiScan('--stats', '-n', '-s', media['path'])
            stats = self.output.parseNapiStats()

            self.assertEquals(0, stats['ok'])
            self.assertEquals(1, stats['skip'])
            self.assertEquals(0, stats['nfo_ok'])
            self.assertEquals(1, stats['nfo_skip'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

    def test_ifSkippingWorksForCoverFiles(self):
        """
        Brief:
        Check cover file skipping

        Procedure:
        1. Prepare a media file.
        2. Program napiprojekt.pl mock
        3. Call napi with a path to media to obtain the subtitles
        4. Call napi again with option -c -n

        Expected Results:
        1. The cover file should be downloaded.
        2. Subsequent call shouldn't download new cover, which should be
        resembled in the stats.
        """
        media = None
        with napi.sandbox.Sandbox() as sandbox:
            media = self.videoAssets.prepareRandomMedia(sandbox)
            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    napi.cover.Cover.fromString(
                        media['asset'], "test cover data"),
                    None,
                    1)

            self.napiScan('--stats', '-c', '-s', media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['cover_ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            napiFs = napi.fs.Filesystem(media)
            self.assertTrue(napiFs.subtitlesExists())
            self.assertTrue(napiFs.coverExists())

            subsPaths = napiFs.getSubtitlesPaths()
            self.assertEquals(1, len(subsPaths))

            self.napiScan('--stats', '-c', '-s', media['path'])
            stats = self.output.parseNapiStats()

            self.assertEquals(0, stats['ok'])
            self.assertEquals(1, stats['skip'])
            self.assertEquals(0, stats['cover_ok'])
            self.assertEquals(1, stats['cover_skip'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

    def test_ifSkippingWorksWithFormatConversion(self):
        """
        Brief:
        Download subtitles with a custom extension specified, skip
        option enabled and format conversion request

        Procedure:
        1. Prepare a media and a subs file for napi mock
        2. Perform a request for programmed media
        3. Make a request again for the same media file but with format
        conversion specified additionally and a skip flag

        Expected Results:
        1. Original subtitles should not be downloaded twice
        2. The original subtitles should be converted to requested format
        3. After conversion both files should exist on the file system
        (original one with prefix prepended)
        """
        media = None
        fromFormat = 'microdvd'
        toFormat = 'subrip'
        extension = 'abcdef'

        with napi.sandbox.Sandbox() as sandbox:
            # generate a media file and subs
            media = self.videoAssets.prepareRandomMedia(sandbox)
            subs = self.subtitlesAssets.prepareRandomMedia(sandbox,
                    fromFormat)

            # program napiprojekt mock - it should be called only once
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromFile(
                        media['asset'],
                        subs['path']),
                    None,
                    None,
                    1)

            # get the subs
            self.napiScan('--stats', '-s', '-e', extension, media['path'])

            # check assertions
            req = self.napiMock.getRequest()
            self.assertTrue(req)
            self.assertEquals(req.method, "POST")
            self.assertEquals(req.url, '/api/api-napiprojekt3.php')
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'napisy pobrano pomyslnie')))

            # check statistics and the file itself
            stats = self.output.parseNapiStats()
            fs = napi.fs.Filesystem(media)
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])
            self.assertTrue(fs.subtitlesExists(None, extension))

            # Make another request, this time with conversion.
            # Original unconverted file should be reused without having to
            # resort to making a HTTP request
            self.napiScan('--stats', '-s',
                    '-e', extension,
                    '-f', toFormat,
                    media['path'])

            # check the stats again
            stats = self.output.parseNapiStats()
            self.assertEquals(1, stats['skip'])
            self.assertEquals(1, stats['conv'])
            self.assertEquals(0, stats['unav'])

            self.assertTrue(fs.subtitlesExists(None, 'srt'))
            self.assertTrue(fs.subtitlesExists('ORIG'))

    def test_ifDownloadWorksWithFormatConversionAndAbbreviations(self):
        """
        Brief:
        Download subtitles with both abbrev and conv-abbrev specified and
        format conversion request

        Procedure:
        1. Prepare media and subs
        2. Program napi mock
        3. Request subs for media with abbreviation AB and conversion
        abbreviation specified as CAB and a request to convert the format

        Expected Results:
        1. The subtitles should be downloaded and converted
        to the requested format
        2. The original subtitles should be renamed to default prefix
        and should contain the abbreviation in the filename
        3. After conversion both files should exist in the filesystem
        (original one with prefix pre-pended)
        4. Converted file should have both abbrev and conversion
        abbrev inserted into the file name
        """
        media = None
        fromFormat = 'microdvd'
        toFormat = 'subrip'
        abbreviation = 'AB'
        convAbbrev = 'CAB'

        with napi.sandbox.Sandbox() as sandbox:
            # generate a media file and subs
            media = self.videoAssets.prepareRandomMedia(sandbox)
            subs = self.subtitlesAssets.prepareRandomMedia(sandbox,
                    fromFormat)

            # program napiprojekt mock - it should be called only once
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromFile(
                        media['asset'],
                        subs['path']),
                    None,
                    None,
                    1)

            # get the subs
            self.napiScan('--stats', '-s',
                    '-f', toFormat,
                    '-a', abbreviation,
                    '--conv-abbrev', convAbbrev,
                    media['path'])

            # check assertions
            req = self.napiMock.getRequest()
            self.assertTrue(req)
            self.assertEquals(req.method, "POST")
            self.assertEquals(req.url, '/api/api-napiprojekt3.php')
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'napisy pobrano pomyslnie')))

            # check statistics and the file itself
            stats = self.output.parseNapiStats()
            fs = napi.fs.Filesystem(media)
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['conv'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            subsFiles = fs.getSubtitlesPaths('ORIG', None,
                    abbreviation, convAbbrev)

            abbrevExt = abbreviation + '.txt'
            convAbbrevExt = '.'.join((abbreviation, convAbbrev, 'srt'))

            self.assertTrue(any(
                [ True if abbrevExt in s else False
                    for s in subsFiles ]))

            self.assertTrue(any(
                [ True if convAbbrevExt in s else False
                    for s in subsFiles ]))

    def test_ifSkippingWorksWithFormatConversionAndAbbreviations(self):
        """
        Brief:
        Check skipping with conversion requested and
        abbreviations specified

        Procedure:
        1. Prepare media and subs files
        2. Program napi mock
        3. Perform a request for subtitles for media file with conversion.
        Request should result in ORIG_ file present in the filesystem
        4. Request subs for media with abbreviation AB and conversion
        abbreviation specified as CAB and a request to convert the format.
        Additionally this request should have the skip flag set.

        Expected Results:

        1. The subtitles shouldn't be downloaded, original available file
        should be converted
        2. After conversion both files should exist in the filesystem
        (original one with prefix prepended)
        3. Converted file should have both abbreviation and conversion
        abbreviation inserted into the file name
        """
        media = None
        fromFormat = 'microdvd'
        toFormat = 'subrip'
        abbreviation = 'AB'
        convAbbrev = 'CAB'

        with napi.sandbox.Sandbox() as sandbox:
            # generate a media file and subs
            media = self.videoAssets.prepareRandomMedia(sandbox)
            subs = self.subtitlesAssets.prepareRandomMedia(sandbox,
                    fromFormat)

            # program napiprojekt mock - it should be called only once
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromFile(
                        media['asset'],
                        subs['path']),
                    None,
                    None,
                    1)

            # get the subs
            self.napiScan('--stats',
                    '-f', toFormat,
                    '-a', abbreviation,
                    '--conv-abbrev', convAbbrev,
                    media['path'])

            # check assertions
            req = self.napiMock.getRequest()
            self.assertTrue(req)
            self.assertEquals(req.method, "POST")
            self.assertEquals(req.url, '/api/api-napiprojekt3.php')
            self.assertTrue(self.output.stdoutContains(
                re.compile(r'napisy pobrano pomyslnie')))

            # check statistics and the file itself
            stats = self.output.parseNapiStats()
            fs = napi.fs.Filesystem(media)
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['conv'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            # make another request
            self.napiScan('--stats',
                    '-s',
                    '-f', toFormat,
                    '-a', abbreviation,
                    '--conv-abbrev', convAbbrev,
                    media['path'])

            stats = self.output.parseNapiStats()
            self.assertEquals(0, stats['ok'])
            self.assertEquals(1, stats['skip'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            subsFiles = fs.getSubtitlesPaths('ORIG', None,
                    abbreviation, convAbbrev)

            abbrevExt = abbreviation + '.txt'
            convAbbrevExt = '.'.join((abbreviation, convAbbrev, 'srt'))

            self.assertTrue(any(
                [ True if abbrevExt in s else False
                    for s in subsFiles ]))

            self.assertTrue(any(
                [ True if convAbbrevExt in s else False
                    for s in subsFiles ]))


class ScanActionHooksTest(napi.testcase.NapiTestCase):

    def test_ifCallsExternalScript(self):
        """
        Brief:
        Check if calls registered user provided scripts

        Procedure:
        1. Prepare media and subs files
        2. Program napi mock
        3. Perform a request for subtitles for media files. Request should
        result in one download and a call to the provided user script/executable.

        Expected Results:

        1. Subtitles should be downloaded
        2. User provided script should be called for each downloaded file
        """
        medias = []
        nMedia = 3
        scpMockerPath = '/usr/local/bin/scpmocker'

        with napi.sandbox.Sandbox() as sandbox:

            # prepare assets
            for _ in xrange(nMedia):
                media = self.videoAssets.prepareRandomMedia(sandbox)
                medias.append(media)

                # program http mock
                self.napiMock.programXmlRequest(
                        media,
                        napi.subtitles.CompressedSubtitles.fromString(
                            media['asset'], "test subtitles"))

            # prepare the fake executable mock
            with napi.scpmocker.ScpMocker(scpMockerPath, sandbox.path) as scpm:
                # program command mock
                toolName = 'myExternalTool'
                scpm.program(toolName, "", 0, nMedia)
                scpm.patchCmd(toolName)

                # call napi
                toolPath = scpm.getPath(toolName)
                self.napiScan('--stats', sandbox.path, '-S', toolPath)

                # verify external script mock calls
                self.assertEquals(nMedia, scpm.getCallCount(toolName))

                # constucts a list of subtitle file names without extension
                callArgs = [
                        os.path.splitext(scpm.getCallArgs(toolName, n + 1))[0]
                        for n in xrange(nMedia) ]

                # constructs a list of media file names without extension
                mediaFiles = [
                        os.path.splitext(m['path'])[0]
                        for m in medias ]

                # compare the results
                self.assertEquals(sorted(callArgs), sorted(mediaFiles))

    def test_ifDoesntCallExternalScriptIfSkipped(self):
        """
        Brief:
        Check if calls registered user provided scripts only for media files
        for which a download was not skipped.

        Procedure:
        1. Prepare media and subs files
        2. Program napi mock
        3. Perform a request for subtitles for media files.
        4. Perform the request again with skipping.

        Expected Results:

        1. Subtitles should be downloaded
        2. User provided script should not be called the second time napi is
        invoked.
        """
        medias = []
        nMedia = 3
        scpMockerPath = '/usr/local/bin/scpmocker'

        with napi.sandbox.Sandbox() as sandbox:

            # prepare assets
            for _ in xrange(nMedia):
                media = self.videoAssets.prepareRandomMedia(sandbox)
                medias.append(media)

                # program http mock
                self.napiMock.programXmlRequest(
                        media,
                        napi.subtitles.CompressedSubtitles.fromString(
                            media['asset'], "test subtitles"))

            # prepare the fake executable mock
            with napi.scpmocker.ScpMocker(scpMockerPath, sandbox.path) as scpm:
                # program command mock
                toolName = 'myExternalTool'
                scpm.program(toolName, "", 0, nMedia * 2)
                scpm.patchCmd(toolName)

                # call napi
                toolPath = scpm.getPath(toolName)
                self.napiScan('--stats', sandbox.path, '-S', toolPath)

                # verify external script mock calls
                self.assertEquals(nMedia, scpm.getCallCount(toolName))

                # # call napi ... again
                # toolPath = scpm.getPath(toolName)
                self.napiScan('--stats', sandbox.path, '-s', '-S', toolPath)

                # call count should remain unchanged
                self.assertEquals(nMedia, scpm.getCallCount(toolName))


if __name__ == '__main__':
    napi.testcase.runTests()
