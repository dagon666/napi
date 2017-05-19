#!/usr/bin/python

from pretenders.client.http import HTTPMock
import os
import re
import sys
import unittest

# integration testing helpers
import napi.assets
import napi.runner
import napi.sandbox
import napi.subtitles
import napi.xml_result

class BasicFetchTest(unittest.TestCase):
    SHELL = "/bin/bash"

    def setUp(self):
        self.napiMock = HTTPMock('napiserver', 8000)
        self.napiprojektUrl = self.napiMock.pretend_url
        self.runner = napi.runner.Runner(self.napiprojektUrl, self.SHELL)
        self.assetsPath = os.path.join(
                os.environ.get('NAPICLIENT_TESTDATA', '/opt/napi/testdata'),
                'testdata',
                'media')
        self.assets = napi.assets.Assets(self.assetsPath)

    def tearDown(self):
        pass

    def test_ifObtainsAvailableSubtitlesForSingleFile(self):
        asset = None
        with napi.sandbox.Sandbox() as sandbox:
            # obtain an asset
            asset = self.assets.prepareRandomMedia(sandbox)

            # program http mock
            self.napiMock.when('POST /api/api-napiprojekt3.php').reply(
                    napi.xml_result.XmlResult(
                        napi.subtitles.CompressedSubtitles.fromString(
                            asset['media'],
                            "test subtitles"),
                        True).toString(),
                    status = 200,
                    times = 1)

            # call napi
            p = self.runner.scan(os.path.join(sandbox.path, asset['name']))
            stdout, stderr = p.communicate()

            # check assertions
            req = self.napiMock.get_request(0)
            self.assertEquals(req.method, "POST")
            self.assertEquals(req.url, '/api/api-napiprojekt3.php')
            self.assertTrue(re.search(r'napisy pobrano pomyslnie', stdout))

            if len(stderr):
                print "STDOUT"
                print stdout
                print "STDERR"
                print stderr

            self.assertEquals(0, len(stderr))

if __name__ == '__main__':

    # inject shell
    if len(sys.argv) > 1:
        BasicFetchTest.SHELL = sys.argv.pop()

    # run unit tests
    unittest.main()
