#!/bin/bash

updateInstallation() {
    local containerName="tests_napiclient"

    echo "Updating napi installation..."
    docker-compose run \
        --name napiclient_update \
        napiclient \
        napiclient/bin/update_installation.sh

    echo "Commiting changes..."
    containerId=$(docker ps -a -q -f "name=napiclient_update")
    docker commit "$containerId" "$containerName"

    # remove the container
    echo "Cleanup..."
    docker rm "$containerId"
}

usage() {
    echo "run_integration_tests.sh [-u]"
    echo "Options:"
    echo
    echo "  -u - update napi installation in container"
    echo
}

while getopts "uh" option; do
    case "$option" in
        u)
            updateInstallation
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
    -w /mnt/tests \
    napiclient \
    python -m unittest discover -vfs integration_tests
