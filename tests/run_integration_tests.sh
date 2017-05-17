#!/bin/bash

docker-compose run \
    --rm \
    -w /mnt/tests \
    napiclient \
    python -m unittest discover -vfs integration_tests
