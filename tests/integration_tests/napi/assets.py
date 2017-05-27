#!/usr/bin/python

import json
import os
import random
import shutil
import uuid

class Assets(object):
    """
    Implements simple media file management
    """

    ASSETS_JSON = 'assets.json'
    DEFAULT_EXT = 'avi'
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
        Copies selected asset file to given sandbox under given name
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

            name = '.'.join((uuid.uuid4().hex, ext))

        return self._prepareMedia(sandbox,
                asset,
                name)

    def prepareMedia(self, sandbox, assetId, name):
        """
        Prepare media out of specific asset
        """
        return self._prepareMedia(sandbox,
                self.assets['assets'][assetId], name)

