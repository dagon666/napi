#!/usr/bin/python

import re
import unittest

import napi.fs
import napi.sandbox
import napi.subtitles
import napi.testcase

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
            media = self.assets.prepareRandomMedia(sandbox)

            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"))

            self.napiScan('--stats', '-e', ext, media['path'])

            stats = self.output.parseStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            self.assertTrue(
                    napi.fs.Filesystem(media).subtitlesExists(ext))

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
            media = self.assets.prepareRandomMedia(sandbox)
            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    None,
                    None,
                    1)

            self.napiScan('--stats', media['path'])

            stats = self.output.parseStats()
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
            stats = self.output.parseStats()

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
            media = self.assets.prepareRandomMedia(sandbox)
            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    None,
                    None,
                    1)

            self.napiScan('--stats', '-e', ext, media['path'])

            stats = self.output.parseStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            napiFs = napi.fs.Filesystem(media)
            self.assertTrue(napiFs.subtitlesExists(ext))

            subsPaths = napiFs.getSubtitlesPaths(ext)
            self.assertEquals(1, len(subsPaths))

            # hashed file - to be able to track file content modifications
            subtitles = napi.fs.HashedFile(subsPaths[0])

            self.napiScan('--stats', '-s', '-e', ext, media['path'])
            stats = self.output.parseStats()

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
            media = self.assets.prepareRandomMedia(sandbox)
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

            stats = self.output.parseStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            napiFs = napi.fs.Filesystem(media)
            self.assertTrue(napiFs.subtitlesExists(ext, abbrev))

            subsPaths = napiFs.getSubtitlesPaths(ext, abbrev)
            self.assertEquals(1, len(subsPaths))

            # hashed file - to be able to track file content modifications
            subtitles = napi.fs.HashedFile(subsPaths[0])

            self.napiScan('--stats', '-s', '-e', ext,
                    '-a', abbrev, media['path'])

            stats = self.output.parseStats()
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
            media = self.assets.prepareRandomMedia(sandbox)
            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    None,
                    None,
                    1)

            self.napiScan('--stats', '-e', ext, media['path'])

            stats = self.output.parseStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            napiFs = napi.fs.Filesystem(media)
            self.assertTrue(napiFs.subtitlesExists(ext, abbrev, convAbbrev))

            # check number of subs files, just to be sure that there's only one
            subsPaths = napiFs.getSubtitlesPaths(ext, abbrev, convAbbrev)
            self.assertEquals(1, len(subsPaths))

            self.napiScan('--stats', '-s', '-e', ext,
                    '-a',
                    abbrev,
                    '--conv-abbrev',
                    convAbbrev,
                    media['path'])

            stats = self.output.parseStats()
            self.assertEquals(0, stats['ok'])
            self.assertEquals(1, stats['skip'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            # check again, number of subs
            subsPaths = napiFs.getSubtitlesPaths(ext, abbrev, convAbbrev)
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
            media = self.assets.prepareRandomMedia(sandbox)
            # program http mock
            self.napiMock.programXmlRequest(
                    media,
                    napi.subtitles.CompressedSubtitles.fromString(
                        media['asset'], "test subtitles"),
                    None,
                    None,
                    1)

            self.napiScan('--stats', '-e', ext, media['path'])

            stats = self.output.parseStats()
            self.assertEquals(1, stats['ok'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            napiFs = napi.fs.Filesystem(media)
            self.assertTrue(napiFs.subtitlesExists(ext, abbrev, convAbbrev))

            # check number of subs files, just to be sure that there's only one
            subsPaths = napiFs.getSubtitlesPaths(ext, abbrev, convAbbrev)
            self.assertEquals(1, len(subsPaths))

            origSubs = napi.fs.HashedFile(subsPaths[0])

            self.napiScan('--stats', '-s', '-e', ext,
                    '-a',
                    abbrev,
                    '--conv-abbrev',
                    convAbbrev,
                    '-M',
                    media['path'])

            stats = self.output.parseStats()
            self.assertEquals(0, stats['ok'])
            self.assertEquals(1, stats['skip'])
            self.assertEquals(1, stats['total'])
            self.assertEquals(0, stats['unav'])

            # check again, number of subs
            subsPaths = napiFs.getSubtitlesPaths(ext, abbrev, convAbbrev)
            self.assertEquals(1, len(subsPaths))

            # make sure we've got the file with abbrev, not conv-abbrev
            self.assertTrue(re.search(abbrev, subsPaths[0]))

            movedSubs = napi.fs.HashedFile(subsPaths[0])
            self.assertEquals(origSubs, movedSubs)



#
##>TESTSPEC
##
## Brief:
##
## check nfo skipping
##
## Preconditions:
## - napi.sh & subotage.sh should be visible in public $PATH
## - media file for which the nfo is available
##
## Procedure:
## - specify the nfo request
## - specify the skip flag
## - fetch the nfo file
## - do another subsequent call
##
## Expected results:
## - the nfo file should be downloaded
## - subsequent call shouldn't download new nfo, which should be resembled in the stats
##
#NapiTest::clean_testspace();
#copy $NapiTest::assets . '/av1.dat', $test_file_path;
#
#$o = NapiTest::qx_napi($shell, " -n --stats -s " . $test_file_path);
#%o = NapiTest::parse_summary($o);
#
#ok ( -e $test_nfo_path, "check for the nfo file" );
#
#is ($o{ok}, 1, "number of downloaded");
#is ($o{skip}, 0, "number of skipped");
#is ($o{nfo_ok}, 1, "number of downloaded nfo");
#is ($o{nfo_skip}, 0, "number of skipped nfo");
#
#
#$o = NapiTest::qx_napi($shell, " -n --stats -s " . $test_file_path);
#%o = NapiTest::parse_summary($o);
#ok ( -e $test_nfo_path, "check for the nfo file" );
#
#is ($o{ok}, 0, "number of downloaded");
#is ($o{skip}, 1, "number of skipped");
#is ($o{nfo_ok}, 0, "number of downloaded nfo");
#is ($o{nfo_skip}, 1, "number of skipped nfo");
#
#
##>TESTSPEC
##
## Brief:
##
## check cover skipping
##
## Preconditions:
## - napi.sh & subotage.sh should be visible in public $PATH
## - media file for which the cover is available
##
## Procedure:
## - specify the cover request
## - specify the skip flag
## - fetch the cover file
## - do another subsequent call
##
## Expected results:
## - the cover file should be downloaded
## - subsequent call shouldn't download new cover, which should be resembled in the stats
##
#NapiTest::clean_testspace();
#copy $NapiTest::assets . '/av1.dat', $test_file_path;
#
#$o = NapiTest::qx_napi($shell, " -c --stats -s " . $test_file_path);
#%o = NapiTest::parse_summary($o);
#
#ok ( -e $test_cover_path, "check for the cover file" );
#
#is ($o{ok}, 1, "number of downloaded");
#is ($o{skip}, 0, "number of skipped");
#is ($o{cover_ok}, 1, "number of downloaded cover");
#is ($o{cover_skip}, 0, "number of skipped cover");
#
#
#$o = NapiTest::qx_napi($shell, " -c --stats -s " . $test_file_path);
#%o = NapiTest::parse_summary($o);
#ok ( -e $test_cover_path, "check for the cover file" );
#
#is ($o{ok}, 0, "number of downloaded");
#is ($o{skip}, 1, "number of skipped");
#is ($o{cover_ok}, 0, "number of downloaded cover");
#is ($o{cover_skip}, 1, "number of skipped cover");





##>TESTSPEC
##
## Brief:
##
## Download subtitles with a custom extension specified, skip option enabled and format conversion request
##
## Preconditions:
## - napi.sh & subotage.sh should be visible in public $PATH
## - media file for which the subtitles are available
## - subtitles file should (with a custom extension) should already exist in the FS
##
## Procedure:
## - specify a custom extension for the probed media file
## - specify the skip flag
## - specify conversion request
##
## Expected results:
## - original subtitles should not be downloaded twice
## - the original subtitles should be converted to requested format
## - after conversion both files should exist in the filesystem (original one with prefix prepended)
##
#$o = NapiTest::qx_napi($shell, " --stats -f subrip -s -e orig " . $test_file_path);
#%o = NapiTest::parse_summary($o);
#is ( -e $test_txt_path =~ s/\.[^\.]+$/\.srt/r,
#		1,
#		"testing skipping with already downloaded original" );
#
#ok ( ! -e $test_txt_path =~ s/\.[^\.]+$/\.orig/r,
#		"checking if original file has been removed" );
#
#is ($o{ok}, 0, "number of skipped");
#is ($o{conv}, 1, "number of converted");
#NapiTest::clean_testspace();
#
#
##>TESTSPEC
##
## Brief:
##
## Download subtitles with both abbrev and conv-abbrev specified and format conversion request
##
## Preconditions:
## - napi.sh & subotage.sh should be visible in public $PATH
## - media file for which the subtitles are available
##
## Procedure:
## - specify the abbreviation as AB
## - specify the conv-abbreviation as CAB
## - specify conversion request
##
## Expected results:
## - the subtitles should be downloaded and converted to the requested format
## - the original subtitles should be renamed to default prefix and should contain the abbreviation in the filename
## - after conversion both files should exist in the filesystem (original one with prefix prepended)
## - converted file should have both abbrev and conversion abbrev inserted into the file name
##
#copy $NapiTest::assets . '/av1.dat', $test_file_path;
#$o = NapiTest::qx_napi($shell, " --stats -f subrip -s -a AB --conv-abbrev CAB " . $test_file_path);
#%o = NapiTest::parse_summary($o);
#
#ok ( -e $test_orig_txt_path =~ s/\.([^\.]+)$/\.AB\.$1/r,
#		"check for original file" );
#
#ok ( -e $test_txt_path =~ s/\.([^\.]+)$/\.AB\.CAB\.srt/r,
#		"checking for converted file and abbreviations" );
#
#is ($o{ok}, 1, "number of downloaded");
#is ($o{conv}, 1, "number of converted");
#
#
##>TESTSPEC
##
## Brief:
##
## check skipping with conversion requested and abbreviations specified
##
## Preconditions:
## - the ORIG_ file should be present
## - the converted file should be absent
## - napi.sh & subotage.sh should be visible in public $PATH
## - media file for which the subtitles are available
##
## Procedure:
## - specify the abbreviation as AB
## - specify the conv-abbreviation as CAB
## - specify conversion request
## - specify the skip flag
##
## Expected results:
## - the subtitles shouldn't be downloaded original available file should be converted
## - after conversion both files should exist in the filesystem (original one with prefix prepended)
## - converted file should have both abbrev and conversion abbrev inserted into the file name
##
#unlink $test_txt_path =~ s/\.([^\.]+)$/\.AB\.CAB\.srt/r;
#$o = NapiTest::qx_napi($shell, " --stats -f subrip -s -a AB --conv-abbrev CAB " . $test_file_path);
#%o = NapiTest::parse_summary($o);
#
#ok ( -e $test_orig_txt_path =~ s/\.([^\.]+)$/\.AB\.$1/r,
#		"check for original file" );
#
#ok ( -e $test_txt_path =~ s/\.([^\.]+)$/\.AB\.CAB\.srt/r,
#		"checking for converted file and abbreviations" );
#
#is ($o{ok}, 0, "number of downloaded");
#is ($o{skip}, 1, "number of skipped");
#is ($o{conv}, 1, "number of converted");
#

if __name__ == '__main__':
    napi.testcase.runTests()
