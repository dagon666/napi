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
        cmd = ('napi.sh',) + args
        print cmd
        return subprocess.Popen(
                cmd,
                executable = self.bash,
                shell = True,
                bufsize = 1024,
                stderr = subprocess.PIPE,
                stdout = subprocess.PIPE)

    def scan(self, *args):
        return self.execute('scan', *args)
