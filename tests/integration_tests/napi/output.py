#!/usr/bin/python

import re

class Parser(object):

    DELIMITER_LEN = 20

    def __init__(self, scriptStdout,
            scriptStderr,
            returnCode):
        self.scriptStdout = scriptStdout
        self.scriptStderr = scriptStderr
        self.returnCode = returnCode

    def parseNapiStats(self):
        """
        Extracts napi stats from the output stream
        """
        tokens = [ 'OK', 'UNAV', 'SKIP', 'CONV',
                'COVER_OK', 'COVER_UNAV', 'COVER_SKIP',
                'NFO_OK', 'NFO_UNAV', 'NFO_SKIP', 'TOTAL', 'CONV_CHARSET' ]
        results = {}
        for token in tokens:
            m = re.search(r'{} -> (\d+)'.format(token),
                    self.scriptStdout)
            results[token.lower()] = int(m.group(1) if m else 0)
        return results

    def stdoutContains(self, regex):
        return re.search(regex, self.scriptStdout)

    def stderrContains(self, regex):
        return re.search(regex, self.scriptStderr)

    def isSuccess(self):
        return self.returnCode == 0

    def hasErrors(self):
        return len(self.scriptStderr) or not self.isSuccess()

    def printStdout(self):
        print "STDOUT"
        print self.scriptStdout
        print "=" * self.DELIMITER_LEN

    def printStderr(self):
        print "STDERR"
        print self.scriptStderr
        print "=" * self.DELIMITER_LEN

