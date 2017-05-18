#!/bin/bash

RESULT="failed"

#
# execute the unit tests
#
docker-compose run \
    --rm \
    napitester bash -s <<CMD_EOF && RESULT="succeeded"

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
    exit 0
CMD_EOF

# send notifications
notify-send "Tests ${RESULT}"
