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
                'testdata',
                'media')
        self.assets = assets.Assets(self.assetsPath)

        # should be used to store the napi output
        self.output = None
        self.isStderrExpected = False

    def tearDown(self):
        if (self.output and
                self.output.hasErrors() and
                not self.isStderrExpected):
            self.output.printStdout()
            self.output.printStderr()

    def napiExecute(self, *args):
        self.output = self.runner.execute(*args)

    def napiScan(self, *args):
        self.output = self.runner.scan(*args)

    def napiDownload(self, *args):
        self.output = self.runner.download(*args)

    def napiSubtitles(self, *args):
        self.output = self.runner.subtitles(*args)

    def napiSearch(self, *args):
        self.output = self.runner.search(*args)

def runTests():
    # inject shell
    if len(sys.argv) > 1:
        NapiTestCase.SHELL = sys.argv.pop()

    # run unit tests
    unittest.main()

