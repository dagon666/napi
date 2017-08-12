#!/usr/bin/python

import logging
import sys
import os

def prepareLogging(logLevel):
    formatter = logging.Formatter('%(asctime)s %(message)s')

    handler = (logging.StreamHandler(sys.stderr))
    handler.setFormatter(formatter)
    handler.setLevel(logLevel)

    logger = logging.getLogger()
    logger.setLevel(logLevel)
    logger.addHandler(handler)

thresholdIndex = os.environ.get('NAPI_INTEGRATION_TESTS_LOGLEVEL', 0)
threshold = logging.DEBUG

try:
    thresholds = [ logging.INFO, logging.DEBUG ]
    mappedThreshold = thresholds[int(thresholdIndex)]
    threshold = mappedThreshold
except IndexError, ValueError:
    pass

prepareLogging(threshold)
