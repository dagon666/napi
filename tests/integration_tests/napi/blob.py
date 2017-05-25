#!/usr/bin/python2

import base64
import hashlib
import logging
import os
import uuid
import subprocess
import tempfile

from . import sandbox

class Blob(object):
    """
    Abstraction around data blob obtained from napi
    """
    def __init__(self, objectId, data):
        self.objectId = objectId
        self.data = data
        self.logger = logging.getLogger()

    def getId(self):
        return self.objectId

    def getHash(self):
        md5 = hashlib.md5()
        md5.update(self.data)
        return md5.hexdigest()

    def getSize(self):
        return len(self.data)

    def getData(self):
        return self.data

    def getBase64(self):
        return base64.b64encode(self.data)

    @classmethod
    def fromFile(cls, objectId, path):
        with open(path, 'rb') as inputFile:
            return cls(objectId, inputFile.read())

    @classmethod
    def fromString(cls, objectId, data):
        return cls(objectId, data)


class CompressedBlob(Blob):
    """
    Abstraction around compressed data blob
    """
    def __init__(self, objectId, data, fileName, password = None):
        """
        Compress provided data
        data - data to be compressed
        fileName - name of the compressed file in archive
        """
        super(CompressedBlob, self).__init__(objectId, data)
        self.uncompressedData = self.data

        with sandbox.Sandbox() as sbx:
            filePath = os.path.join(sbx.path, fileName)

            # create a file with data in the sandbox
            with open(filePath, 'w+') as dataFile:
                dataFile.write(data)

            # create an archive name
            archiveName = os.path.join(sbx.path,
                    uuid.uuid4().hex)

            # capture output
            with tempfile.TemporaryFile() as cStdout, tempfile.TemporaryFile() as cStderr:
                try:
                    cmd7z = [ '7z', 'a' ]
                    if password:
                        cmd7z.append("-p%s" % (password))
                    cmd7z.extend(['-m01=bzip2', archiveName, filePath])

                    subprocess.check_call(cmd7z,
                            stdout=cStdout, stderr=cStderr)

                    # read back the archive file
                    with open(archiveName + '.7z', 'rb') as archiveFile:
                        self.data = archiveFile.read()

                except subprocess.CalledProcessError as e:
                    self.logger.error("Unable to prepare subtitles: " +
                            str(e))
                    self.logger.info(cStdout.read())
                    self.logger.info(cStderr.read())

                else:
                    self.logger.info("OK")

    def getUncompressedData(self):
        return self.uncompressedData

    def getUncompressedSize(self):
        return len(self.uncompressedData)

    def getUncompressedBase64(self):
        return base64.b64encode(self.uncompressedData)

