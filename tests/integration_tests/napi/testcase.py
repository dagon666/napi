#!/usr/bin/python

import os
import sys
import unittest

from . import assets
from . import mock
from . import runner

class NapiTestCase(unittest.TestCase):
    SHELL = "/bin/bash"

    def setUp(self):
        self.napiMock = mock.NapiprojektMock()
        self.napiprojektUrl = self.napiMock.getUrl()
        self.runner = runner.Runner(self.napiprojektUrl, self.SHELL)
        self.assetsPath = os.path.join(
                os.environ.get('NAPICLIENT_TESTDATA', '/opt/napi/testdata'),
                'testdata')

        self.videoAssetsPath = os.path.join(
                self.assetsPath, 'media')

        self.subtitlesAssetsPath = os.path.join(
                self.assetsPath, 'subtitles')

        self.videoAssets = assets.VideoAssets(self.videoAssetsPath)
        self.subtitlesAssets = assets.SubtitlesAssets(self.subtitlesAssetsPath)

        # should be used to store the napi output
        self.output = None
        self.isStderrExpected = False

        self.testTraceFile = "testrun_" + self.id() + ".log"
        self.testTraceFilePath = self.testTraceFile

    def tearDown(self):
        if (self.output and
                self.output.hasErrors() and
                not self.isStderrExpected):
            self.output.printStdout()
            self.output.printStderr()
        else:
            if (os.path.exists(self.testTraceFilePath)):
                os.remove(self.testTraceFilePath)

    def napiExecute(self, *args):
        self.output = self.runner.executeNapi(self.testTraceFilePath,
                *args)

    def subotageExecute(self, *args):
        self.output = self.runner.executeSubotage(self.testTraceFilePath,
                *args)

    def napiScan(self, *args):
        self.output = self.runner.scan(self.testTraceFilePath,
                *args)

    def napiDownload(self, *args):
        self.output = self.runner.download(self.testTraceFilePath,
                *args)

    def napiSubtitles(self, *args):
        self.output = self.runner.subtitles(self.testTraceFilePath,
                *args)

    def napiSearch(self, *args):
        self.output = self.runner.search(self.testTraceFilePath,
                *args)

def runTests():
    # inject shell
    if len(sys.argv) > 1:
        NapiTestCase.SHELL = sys.argv.pop()

    # run unit tests
    unittest.main()

