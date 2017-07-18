#!/bin/bash

set -e

# run all tests using different implementations of awk
./run_unit_tests.sh
./run_unit_tests.sh -a /usr/bin/mawk
./run_unit_tests.sh -a /usr/bin/original-awk

# run all integration tests
./run_integration_tests.sh
