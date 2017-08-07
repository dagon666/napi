#!/usr/bin/python2

import os
import hashlib

class HashedFile(object):
    """
    Represents a file with a hash, to be able to detect if file has been
    modified or not.
    """

    def __init__(self, path):
        self.path = path
        try:
            self.hash = self._hash()
        except RuntimeError as e:
            logging.error(str(e))
            self.hash = None

    def _hash(self):
        if not os.path.exists(self.path):
            raise RuntimeError("Path {} doesn't exist".format(self.path))

        h = hashlib.sha256()
        with open(self.path, "rb") as fileObj:
            def readChunk():
                chunkSize = 2048
                return fileObj.read(chunkSize)

            for chunk in iter(readChunk, ''):
                h.update(chunk)

        return h.hexdigest()

    def getHash(self):
        return self.hash

    def hasChanged(self):
        if not self.hash:
            return False
        return self._hash() != self.hash

    def __eq__(self, other):
        return self.hash == other.hash


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

    def createSubtitlesFileNames(self,
            prefix = None,
            extension = None,
            abbreviation = None,
            conversionAbbreviation = None):
        extensions = set([ extension ] if extension
                else [ 'srt', 'sub', 'txt' ])

        abbreviations = []
        suffixes = []
        prefixes = [ self.noExtension ]

        if prefix:
            prefixes.append('_'.join((prefix, self.noExtension)))

        if abbreviation:
            abbreviations.append(abbreviation)

        if conversionAbbreviation:
            abbreviations.append(conversionAbbreviation)

        if abbreviation and conversionAbbreviation:
            abbreviations.append('.'.join(
                (abbreviation, conversionAbbreviation)))

        suffixes = [ '.'.join((abr, ext)) for ext in extensions
                for abr in abbreviations ]
        suffixes.extend(extensions)

        # generate all possible file names
        return [ '.'.join((p,s)) for p in prefixes for s in suffixes ]

    def createNfoFileName(self):
        return self.noExtension + '.nfo'

    def createCoverFileName(self):
        return self.noExtension + '.jpg'

    def createXmlFileName(self):
        return self.noExtension + '.xml'

    def subtitlesExists(self, prefix = None, extension = None,
            abbreviation = None, conversionAbbreviation = None):
        paths = self.getSubtitlesPaths(prefix, extension,
                abbreviation, conversionAbbreviation)
        return True if len(paths) > 0 else False

    def getSubtitlesPaths(self, prefix = None, extension = None,
            abbreviation = None, conversionAbbreviation = None):
        paths = [ p for p in map(
            lambda f: os.path.join(self.path, f),
            self.createSubtitlesFileNames(prefix, extension,
                abbreviation, conversionAbbreviation))
            if os.path.exists(p) ]
        return paths

    def coverExists(self):
        return self._fileExists(self.createCoverFileName())

    def nfoExists(self):
        return self._fileExists(self.createNfoFileName())

    def xmlExists(self):
        return self._fileExists(self.createXmlFileName())
