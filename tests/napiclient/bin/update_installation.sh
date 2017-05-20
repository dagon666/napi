#!/bin/bash

cd "$(mktemp -d)" || {
    echo "Unable to create build directory"
    exit 1
}

cmake /mnt
make && make install
