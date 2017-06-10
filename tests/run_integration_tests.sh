#!/bin/bash

updateInstallation() {
    local containerName="tests_napiclient"

    echo "Updating napi installation..."
    docker-compose run \
        -u 0 \
        --name napiclient_update \
        napiclient \
        napiclient/bin/update_installation.sh

    echo "Commiting changes..."
    containerId=$(docker ps -a -q -f "name=napiclient_update")
    docker commit "$containerId" "$containerName"

    # remove the container
    echo "Cleanup..."
    docker rm -f "$containerId"
}

usage() {
    echo "run_integration_tests.sh [-u]"
    echo "Options:"
    echo
    echo "  -u - update napi installation in container and run tests"
    echo "  -U - update napi installation in container and exit (doesn't run tests)"
    echo
}

while getopts "uUh" option; do
    case "$option" in
        u)
            updateInstallation
            ;;

        U)
            # only update, don't run tests
            updateInstallation
            exit 0
            ;;

        h)
            usage
            exit 0
            ;;

        *)
            echo "Unexpected argument" >/dev/stderr
            usage
            exit 1
            ;;
    esac
done

# run the tests
docker-compose run \
    --rm \
    napiclient \
    python -m unittest discover -vfs integration_tests
