#!/usr/bin/python

import napi.testcase

class HelpTest(napi.testcase.NapiTestCase):

    def test_ifMainHelpDoesNotProduceErrors(self):
        self.napiExecute('--help')
        self.assertFalse(self.output.hasErrors())

    def test_ifActionsHelpDoesNotProduceErrors(self):
        actions = {
                'search': self.napiSearch,
                'subtitles': self.napiSubtitles,
                'download': self.napiDownload,
                'scan': self.napiScan
                }

        for action, func in actions.items():
            func('--help')
            self.assertFalse(self.output.hasErrors())



if __name__ == '__main__':
    napi.testcase.runTests()
