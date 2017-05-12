#!/usr/bin/python

import os
import shutil
import tempfile

class Runner(object):



    def __init__(self, bash = None, awk = None):
        self.sandbox = tempfile.mkdtemp()
        self.bash = shell
        self.awk = awk
        self._prepareLayout()
        self._prepareInterpreters();
        self._setupPaths()
        self._install()

    def __enter__(self):
        return self

    def __exit__(self, *args, **kwargs):
        shutil.rmtree(self.sandbox)

    def _prepareLayout(self):
        for d in [ [ 'bin' ], [ 'usr', 'share' ], [ 'usr', 'bin' ] ]:
            os.makedirs(self._getPath(*d))

    def _prepareInterpreters(self):
        if self.bash && os.path.exists(self.bash):
            os.symlink(self.bash, self._getPath('bin','bash'))




    def _getPath(self, *paths):
        return os.path.join(self.sandbox, *paths)

    def _setupPaths(self):
        os.environ['PATH'] += os.pathsep + self._getPath('bin')
        os.environ['PATH'] += os.pathsep + self._getPath('usr', 'bin')

    def _install(self):
        # TODO wip - installer needed
        pass

    def execute(self, *args, **kwargs):
        # TODO wip
        pass
