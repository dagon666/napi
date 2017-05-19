#!/usr/bin/python2

import hashlib
import os
import subprocess
import tempfile
import uuid

class Subtitles(object):
    """
    Abstraction around a subtitles file
    """
    def __init__(self, asset, data):
        self.asset = asset
        self.data = data

    def getId(self):
        return self.asset['md5']

    def getHash(self):
        md5 = hashlib.md5()
        md5.update(self.data)
        return md5.hexdigest()

    def getSize(self):
        return len(self.data)

    def getData(self):
        return self.data

    @classmethod
    def fromFile(cls, asset, path):
        with open(path, 'rb') as inputFile:
            return cls(asset, inputFile.read())

    @classmethod
    def fromString(cls, asset, data):
        return cls(asset, data)


class CompressedSubtitles(Subtitles):
    """
    Abstraction around subtitles stored in the 7z archive
    """
    PASSWORD = 'iBlm8NTigvru0Jr0'

    def __init__(self, asset, data):
        from . import sandbox
        super(CompressedSubtitles, self).__init__(asset, data)

        with sandbox.Sandbox() as sandbox:
            try:
                subsName = os.path.join(sandbox.path,
                        asset['md5'])
            except KeyError:
                subsName = os.path.join(sandbox.path, 'unknown')

            subsName = subsName + '.txt'

            with open(subsName, 'w+') as subsFile:
                subsFile.write(data)

            archiveName = os.path.join(sandbox.path,
                    uuid.uuid4().hex)

            passwdArg = "-p%s" % (self.PASSWORD)
            subprocess.call([ '7z', 'a', passwdArg,
                '-m01=bzip2',
                archiveName,
                subsName])

            with open(archiveName + '.7z', 'rb') as archiveFile:
                self.compressedData = archiveFile.read()

    def getSize(self):
        return len(self.compressedData)

    def getData(self):
        return self.compressedData
