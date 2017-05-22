#!/usr/bin/python

import os
import subprocess
import logging

from . import output as napiOutput

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

    def execute(self, *args):
        cmd = (self.bash, 'napi.sh',) + args
        self.logger.error(cmd)
        process = subprocess.Popen(
                cmd,
                shell = False,
                bufsize = 1024,
                stderr = subprocess.PIPE,
                stdout = subprocess.PIPE)

        output = process.communicate()
        return napiOutput.Parser(*output)

    def scan(self, *args):
        return self.execute('scan', '-v', '3', *args)
