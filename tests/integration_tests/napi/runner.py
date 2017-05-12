#!/usr/bin/python

import os
import shutil
import subprocess
import tempfile

class Runner(object):

    def __init__(self, bash = None):
        self.sandbox = tempfile.mkdtemp()
        self.bash = bash if bash else '/bin/bash'
        self._prepareLayout()
        self._setupPaths()
        self._install()

    def __enter__(self):
        return self

    def __exit__(self, *args, **kwargs):
        shutil.rmtree(self.sandbox)

    def _prepareLayout(self):
        for d in [ [ 'bin' ], [ 'usr', 'share' ], [ 'usr', 'bin' ] ]:
            os.makedirs(self._getPath(*d))

    def _getPath(self, *paths):
        return os.path.join(self.sandbox, *paths)

    def _setupPaths(self):
        os.environ['PATH'] += os.pathsep + self._getPath('bin')
        os.environ['PATH'] += os.pathsep + self._getPath('usr', 'bin')

    def _install(self):
        # TODO wip - installer needed
        pass

    def execute(self, *args):
        return subprocess.Popen(
                'napi.sh',
                *args,
                executable = self.bash,
                shell = True,
                stderr = subprocess.PIPE,
                stdout = subprocess.PIPE)
