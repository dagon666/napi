#!/bin/bash

DOCKER_IMAGE="napitester"

#
# build image if it doesn't exist
#
[ -z "$(docker images -q "$DOCKER_IMAGE")" ] &&
    docker build -t "$DOCKER_IMAGE" -f "Dockerfile-${DOCKER_IMAGE}" .

#
# execute the unit tests
#
# shellcheck disable=SC2016
docker run -v "$PWD"/..:/mnt \
    -w /mnt/tests/unit_tests \
    -i napitester bash <<CMD_EOF

    # make an array of unit tests
    tests=( ./*test.sh )

    # run argv unit tests only if provided
    [ $# -gt 0 ] && tests=( "$@" )

    for tc in "\${tests[@]}"; do
        echo " ** executing [\$tc]"
        kcov --exclude-pattern=shunit,mock \
            ../coverage "\$tc" ||
            exit \$?
    done
CMD_EOF
