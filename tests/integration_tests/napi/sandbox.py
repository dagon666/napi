#!/usr/bin/python

import os
import shutil
import tempfile

class Sandbox(object):
    def __init__(self):
        self.create()

    def create(self):
        self.path = tempfile.mkdtemp()

    def destroy(self):
        if os.path.exists(self.path):
            shutil.rmtree(self.path)

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.destroy()
