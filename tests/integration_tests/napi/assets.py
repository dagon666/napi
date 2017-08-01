#!/usr/bin/python

import hashlib
import json
import os
import random
import shutil
import uuid

class Assets(object):
    """
    Implements simple assets file management
    """

    ASSETS_JSON = 'assets.json'
    VERSION = 1

    def __init__(self, path):
        """
        The path to multimedia directory. This directory should contain the
        assets.json - assets description JSON file.
        """
        self.path = path

        with open(os.path.join(self.path, self.ASSETS_JSON), "r") as assetsJson:
            self.assets = json.load(assetsJson)

        if self.assets['version'] is not self.VERSION:
            raise exception.RuntimeError("Unsupported assets version")

    def _prepareMedia(self, sandbox, asset, name):
        """
        Copies selected asset file to given sandbox under given name. Asset
        descriptor is required as a parameter.
        """

        assetPath = os.path.join(self.path, asset['filename'])
        mediaPath = os.path.join(sandbox.path, name)
        shutil.copyfile(assetPath, mediaPath)

        # return a media descriptor
        return { 'name': name, 'path': mediaPath, 'asset': asset }

    def prepareRandomMedia(self, sandbox, name = None):
        """
        Prepares random media file with given name (or generated uuid if name
        not given)
        """
        asset = random.choice(self.assets['assets'])
        # translates file types to extensions
        exts = {
                'mpeg-4': 'mp4'
                }

        if not name:
            ext = (asset['type'] if asset['type'] != 'unknown'
                    else self.DEFAULT_EXT)

            try:
                extMapped = exts[ext]
                ext = extMapped
            except KeyError:
                pass

            nameWithSpaces = ' '.join(
                    (uuid.uuid4().hex, uuid.uuid4().hex))
            name = '.'.join((nameWithSpaces, ext))

        return self._prepareMedia(sandbox,
                asset,
                name)

    def prepareMedia(self, sandbox, assetId, name):
        """
        Prepare media out of specific asset
        """
        return self._prepareMedia(sandbox,
                self.assets['assets'][assetId], name)


class VideoAssets(Assets):
    """
    Implements management of multimedia files assets
    """
    DEFAULT_EXT = 'avi'
    DEFAULT_GENERATED_MEDIA_SIZE = 1024*1024*10

    def _makeFHash(self, md5):
        tIdx = [ 0xe, 0x3, 0x6, 0x8, 0x2 ]
        tMul = [ 2, 2, 5, 4, 3 ]
        tAdd = [ 0, 0xd, 0x10, 0xb, 0x5 ]
        digest = ""

        for i in xrange(5):
            a = tAdd[i]
            m = tMul[i]
            g = tIdx[i]

            t = int(md5[g:g+1],16) + a
            v = int(md5[t:t+2],16)

            x = (v * m) % 0x10
            z = format(x, 'x')
            digest = digest + z
        return digest

    def generateMedia(self,
            sandbox,
            size = DEFAULT_GENERATED_MEDIA_SIZE,
            name = None):
        """
        Prepares a media file with random data inside, with given size.
        A fake asset descriptor will be built on the fly for the
        generated media file.
        """

        ext = self.DEFAULT_EXT
        if not name:
            name = '.'.join((uuid.uuid4().hex, ext))

        mediaPath = os.path.join(sandbox.path, name)

        # prepare fake asset descriptor
        asset = {
            'filename': 'dev-urandom.dat',
            'size': size,
            'f': None,
            'md5': None,
            'type': ext,
            }

        with open('/dev/urandom', 'rb') as randomDev:
            with open(mediaPath, 'wb') as mediaFile:
                mediaFile.write(randomDev.read(size))

        with open(mediaPath, 'rb') as mediaFile:
            md5 = hashlib.md5()
            md5.update(mediaFile.read())
            asset['md5'] = md5.hexdigest()
            asset['f'] = self._makeFHash(asset['md5'])

        return { 'name': name, 'path': mediaPath, 'asset': asset }

class SubtitlesAssets(Assets):
    """
    Implements management of subtitles files assets
    """
    DEFAULT_EXT = 'txt'

