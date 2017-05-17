#!/usr/bin/python

from pretenders.client.http import HTTPMock
import napi.runner
import os
import sys
import unittest

class BasicFetchTest(unittest.TestCase):
    SHELL = "/bin/bash"

    def setUp(self):
        self.napiMock = HTTPMock('napiserver', 8000)
        self.napiprojektUrl = self.napiMock.pretend_url
        self.runner = napi.runner.Runner(self.napiprojektUrl, self.SHELL)

    def tearDown(self):
        pass

    def test_if(self):
        self.assertEquals(0, 1)

if __name__ == '__main__':

    # inject shell
    if len(sys.argv) > 1:
        BasicFetchTest.SHELL = sys.argv.pop()

    # run unit tests
    unittest.main()
