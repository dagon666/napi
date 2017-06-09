#!/usr/bin/python

import re

class Parser(object):

    DELIMITER_LEN = 20

    def __init__(self, napiStdout, napiStderr):
        self.napiStdout = napiStdout
        self.napiStderr = napiStderr

    def parseStats(self):
        """
        Extracts napi stats from the output stream
        """
        tokens = [ 'OK', 'UNAV', 'SKIP', 'CONV',
                'COVER_OK', 'COVER_UNAV', 'COVER_SKIP',
                'NFO_OK', 'NFO_UNAV', 'NFO_SKIP', 'TOTAL', 'CONV_CHARSET' ]
        results = {}
        for token in tokens:
            m = re.search(r'{} -> (\d+)'.format(token),
                    self.napiStdout)
            results[token.lower()] = int(m.group(1) if m else 0)
        return results

    def stdoutContains(self, regex):
        return re.search(regex, self.napiStdout)

    def stderrContains(self, regex):
        return re.search(regex, self.napiStderr)

    def hasErrors(self):
        return len(self.napiStderr)

    def printStdout(self):
        print "STDOUT"
        print self.napiStdout
        print "=" * self.DELIMITER_LEN

    def printStderr(self):
        print "STDERR"
        print self.napiStderr
        print "=" * self.DELIMITER_LEN

