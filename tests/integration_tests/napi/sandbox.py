#!/usr/bin/python

import os
import shutil
import tempfile

class Sandbox(object):
    def __init__(self):
        self.path = tempfile.mkdtemp()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        if os.path.exists(self.path):
            shutil.rmtree(self.path)
