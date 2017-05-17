#!/usr/bin/python

import os
import subprocess

NAPIPROJEKT_BASEURL_DEFAULT = 'http://napiprojekt.pl'

class Runner(object):

    def __init__(self,
            napiprojektUrl = NAPIPROJEKT_BASEURL_DEFAULT,
            bash = None):
        self.bash = bash if bash else '/bin/bash'
        self.napiprojektUrl = napiprojektUrl

        self._prepareEnv()

    def _prepareEnv(self):
        if self.napiprojektUrl != NAPIPROJEKT_BASEURL_DEFAULT:
            os.environ['NAPIPROJEKT_BASEURL'] = self.napiprojektUrl

    def execute(self, *args):
        return subprocess.Popen(
                'napi.sh',
                *args,
                executable = self.bash,
                shell = True,
                stderr = subprocess.PIPE,
                stdout = subprocess.PIPE)
