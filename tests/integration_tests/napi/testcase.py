#!/usr/bin/python

import os
import sys
import unittest
import uuid
import logging

from . import assets
from . import mock
from . import runner

class NapiTestCase(unittest.TestCase):
    SHELL = "/bin/bash"

    def setUp(self):
        self.logger = logging.getLogger()
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

        # trace files
        self.testTraceFilePaths = []

    def tearDown(self):
        if (self.output and
                self.output.hasErrors() and
                not self.isStderrExpected):
            self.output.printStdout()
            self.output.printStderr()
        else:
            self._cleanupTraceFiles()

    def _createTraceFilePath(self):
        self.testTraceFile = "testrun_{}_{}.log".format(
                self.id(), uuid.uuid4().hex)
        testTraceFilePath = self.testTraceFile
        self.testTraceFilePaths.append(testTraceFilePath)
        return testTraceFilePath

    def _cleanupTraceFiles(self):
        for traceFile in self.testTraceFilePaths:
            if os.path.exists(traceFile):
                os.remove(traceFile)

    def napiExecute(self, *args):
        self.output = self.runner.executeNapi(
                self._createTraceFilePath(),
                *args)

    def subotageExecute(self, *args):
        self.output = self.runner.executeSubotage(
                self._createTraceFilePath(),
                *args)

    def napiScan(self, *args):
        self.output = self.runner.scan(
                self._createTraceFilePath(),
                *args)

    def napiDownload(self, *args):
        self.output = self.runner.download(
                self._createTraceFilePath(),
                *args)

    def napiSubtitles(self, *args):
        self.output = self.runner.subtitles(
                self._createTraceFilePath(),
                *args)

    def napiSearch(self, *args):
        self.output = self.runner.search(
                self._createTraceFilePath(),
                *args)

def runTests():
    # inject shell
    if len(sys.argv) > 1:
        NapiTestCase.SHELL = sys.argv.pop()

    # run unit tests
    unittest.main()

