#!/usr/bin/python2

from . import blob

class Cover(blob.Blob):
    """
    Abstraction around a cover delivered in XML
    Cover is just a base64 encoded jpg file
    """

    def __init__(self, asset, data):
        super(Cover, self).__init__(asset['md5'], data)
        self.asset = asset
