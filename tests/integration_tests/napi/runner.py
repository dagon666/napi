#!/usr/bin/python

import os
import shutil
import tempfile

class Runner(object):
    def __init__(self, shell, awk):
        self.sandbox = tempfile.mkdtemp()
        self.shell = shell
        self.awk = awk
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
        pass

    def execute(self, *args, **kwargs):
        pass
