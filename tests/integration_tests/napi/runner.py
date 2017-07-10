#!/usr/bin/python

import os
import subprocess
import logging

from . import output as OutputParser

NAPIPROJEKT_BASEURL_DEFAULT = 'http://napiprojekt.pl'

class Runner(object):

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

    def _execute(self, executable, *args):
        cmd = [self.bash, executable,] + map(str, args)
        self.logger.error(cmd)
        process = subprocess.Popen(
                cmd,
                shell = False,
                bufsize = 1024,
                stderr = subprocess.PIPE,
                stdout = subprocess.PIPE)

        return process.communicate()

    def executeNapi(self, *args):
        output = self._execute('napi.sh', *args)
        return OutputParser.Parser(*output)

    def executeSubotage(self, *args):
        output = self._execute('subotage.sh', *args)
        return OutputParser.Parser(*output)

    def scan(self, *args):
        return self.executeNapi('scan', '-v', '3', *args)

    def download(self, *args):
        return self.executeNapi('download', '-v', '3', *args)

    def subtitles(self, *args):
        return self.executeNapi('subtitles', '-v', '3', *args)

    def search(self, *args):
        return self.executeNapi('search', '-v', '3', *args)
