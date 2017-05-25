#!/usr/bin/python

import logging
import sys

def prepareLogging(logLevel):
    formatter = logging.Formatter('%(asctime)s %(message)s')

    handler = (logging.StreamHandler(sys.stderr))
    handler.setFormatter(formatter)
    handler.setLevel(logLevel)

    logger = logging.getLogger()
    logger.setLevel(logLevel)
    logger.addHandler(handler)

prepareLogging(logging.INFO)
