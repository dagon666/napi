#!/usr/bin/python2

import os

class Filesystem(object):
    """
    This module provides a set of utilities for napiprojekt file
    management
    """
    def __init__(self, media):
        self.media = media
        self.path = os.path.dirname(self.media['path'])

    def _basename(self):
        return os.path.splitext(self.media['name'])[0]

    def _fileExists(self, fileName):
        return os.path.exists(os.path.join(self.path, fileName))

    def createSubtitlesFileNames(self):
        extensions = [ 'srt', 'sub', 'txt' ]
        noExt = self._basename()
        return map(lambda ext: noExt + '.' + ext, extensions)

    def createNfoFileName(self):
        noExt = self._basename()
        return noExt + '.nfo'

    def createCoverFileName(self):
        noExt = self._basename()
        return noExt + '.jpg'

    def createXmlFileName(self):
        noExt = self._basename()
        return noExt + '.xml'

    def subtitlesExists(self):
        paths = [ os.path.exists(p) for p in map(
            lambda f: os.path.join(self.path, f),
            self.createSubtitlesFileNames()) ]
        return any(paths)

    def coverExists(self):
        return self._fileExists(self.createCoverFileName())

    def nfoExists(self):
        return self._fileExists(self.createNfoFileName())

    def xmlExists(self):
        return self._fileExists(self.createXmlFileName())
