#!/usr/bin/python2

import os

class Filesystem(object):
    """
    This module provides a set of utilities for napiprojekt file
    management
    """
    def __init__(self, media):
        self.media = media
        self.path = self._dirname()
        self.noExtension = self._basename()

    def _dirname(self):
        return os.path.dirname(self.media['path'])

    def _basename(self):
        return os.path.splitext(self.media['name'])[0]

    def _fileExists(self, fileName):
        path = os.path.join(self.path, fileName)
        return os.path.exists(path) and os.path.getsize(path) > 0

    def createSubtitlesFileNames(self, abbreviation = None, extension = None):
        extensions = set([ extension ] if extension else [ 'srt', 'sub', 'txt' ])
        noExt = ('.'.join((self.noExtension, abbreviation)) if
                abbreviation else self.noExtension)

        return map(lambda ext: noExt + '.' + ext, extensions)

    def createNfoFileName(self):
        return self.noExtension + '.nfo'

    def createCoverFileName(self):
        return self.noExtension + '.jpg'

    def createXmlFileName(self):
        return self.noExtension + '.xml'

    def subtitlesExists(self, abbreviation = None, extension = None):
        paths = [ os.path.exists(p) for p in map(
            lambda f: os.path.join(self.path, f),
            self.createSubtitlesFileNames(abbreviation, extension)) ]

        return any(paths)

    def coverExists(self):
        return self._fileExists(self.createCoverFileName())

    def nfoExists(self):
        return self._fileExists(self.createNfoFileName())

    def xmlExists(self):
        return self._fileExists(self.createXmlFileName())
