#!/usr/bin/python

import os
import subprocess
import logging

from . import output as OutputParser

NAPIPROJEKT_BASEURL_DEFAULT = 'http://napiprojekt.pl'

class Runner(object):
    testWrapper = "test_wrapper.sh"
    testWrapperPath = os.path.join(
            os.path.dirname(os.path.realpath(__file__)),
            "..", "bin",
            testWrapper)

    def __init__(self,
            napiprojektUrl = NAPIPROJEKT_BASEURL_DEFAULT,
            bash = None):
        self.logger = logging.getLogger()
        self.bash = bash if bash else '/bin/bash'
        self.napiprojektUrl = napiprojektUrl

        self._prepareEnv()

    def _prepareEnv(self):
        if self.napiprojektUrl != NAPIPROJEKT_BASEURL_DEFAULT:
            os.environ['NAPIPROJEKT_BASEURL'] = self.napiprojektUrl

    def _execute(self, executable, testTraceFilePath, *args):

        cmd = [ self.testWrapperPath, testTraceFilePath,
                self.bash, executable, ] + map(str, args)
        self.logger.error(cmd)
        process = subprocess.Popen(
                cmd,
                shell = False,
                bufsize = 1024,
                stderr = subprocess.PIPE,
                stdout = subprocess.PIPE)

        return process.communicate()

    def executeNapi(self, testTraceFilePath, *args):
        output = self._execute('napi.sh', testTraceFilePath, *args)
        return OutputParser.Parser(*output)

    def executeSubotage(self, testTraceFilePath, *args):
        output = self._execute('subotage.sh', testTraceFilePath, *args)
        return OutputParser.Parser(*output)

    def scan(self, testTraceFilePath, *args):
        return self.executeNapi(testTraceFilePath,
                'scan', '-v', '3', *args)

    def download(self, testTraceFilePath, *args):
        return self.executeNapi(testTraceFilePath,
                'download', '-v', '3', *args)

    def subtitles(self, testTraceFilePath, *args):
        return self.executeNapi(testTraceFilePath,
                'subtitles', '-v', '3', *args)

    def search(self, testTraceFilePath, *args):
        return self.executeNapi(testTraceFilePath,
                'search', '-v', '3', *args)
