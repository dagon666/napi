#!/usr/bin/python

import napi.testcase
import unittest

class HelpTest(napi.testcase.NapiTestCase):

    def test_ifMainHelpDoesNotProduceErrors(self):
        """
        Brief:
        Test if the main action doesn't produce any output on stderr

        Procedure:
        1. Call napi.sh --help

        Expected Results:
        No output on stderr.
        """
        self.napiExecute('--help')
        self.assertFalse(self.output.hasErrors())

    def test_ifActionsHelpDoesNotProduceErrors(self):
        """
        Brief:
        Test if none of the actions produce any output on stderr

        Procedure:
        1. Call napi <action> --help for all actions

        Expected Results:
        No output on stderr.
        """
        actions = {
                'search': self.napiSearch,
                'subtitles': self.napiSubtitles,
                'download': self.napiDownload,
                'scan': self.napiScan
                }

        for action, func in actions.items():
            func('--help')
            self.assertFalse(self.output.hasErrors())

    def test_ifSubotageHelpDoesNotProduceErrors(self):
        """
        Brief:
        Test if call to subotage.sh's help doesn't generate any output on stderr

        Procedure:
        1. Call subotage.sh --help

        Expected Results:
        No output on stderr.
        """
        self.subotageExecute('--help')
        self.assertFalse(self.output.hasErrors())

if __name__ == '__main__':
    napi.testcase.runTests()
