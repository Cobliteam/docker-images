#!/usr/bin/env bash

set -eo pipefail

cmd="$1"
shift

case "$cmd" in
build|push)
    # The dash is important here
    DOCKER_REV_TAG="-$(git rev-parse --short HEAD)"
    export DOCKER_REV_TAG
    docker-compose "$cmd" "$@"

    if [ "$TAG_LATEST" -eq 1 ]; then
        unset DOCKER_REV_TAG
        docker-compose "$cmd" "$@"
    fi
;;
pull)
    ./pull-cache-from-images.py "$@"
esac
