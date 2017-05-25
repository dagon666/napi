#!/usr/bin/python2

from . import blob

class Subtitles(blob.Blob):
    """
    Abstraction around a subtitles file
    """
    def __init__(self, asset, data):
        super(Subtitles, self).__init__(asset['md5'], data)
        self.asset = asset

class CompressedSubtitles(blob.CompressedBlob):
    """
    Abstraction around subtitles stored in the 7z archive
    """

    PASSWORD = 'iBlm8NTigvru0Jr0'

    def __init__(self, asset, data):
        self.asset = asset

        # generate the subtitles file name
        try:
            subsName = asset['md5'] + '.txt'
        except KeyError:
            subsName = 'unknown.txt'

        super(CompressedSubtitles, self).__init__(
                asset['md5'],
                data,
                subsName,
                self.PASSWORD)
