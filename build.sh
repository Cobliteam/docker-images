#!/usr/bin/env bash

set -ex -o pipefail

cmd="$1"
shift

# The dash is important here
DOCKER_REV_TAG="-$(git rev-parse --short HEAD)"
export DOCKER_REV_TAG

do_cmd() {
    local cmd="$1"
    shift

    docker-compose "$cmd" "$@"

    if [[ "$TAG_LATEST" -eq 1 ]]; then
        unset DOCKER_REV_TAG
        docker-compose "$cmd" "$@"
    fi
}

case "$cmd" in
build)
    # Make sure file permissions are uniform to avoid accidental cache busting
    worktree=$(mktemp -d)
    trap "rm -rf '$worktree'" EXIT

    cp -a "${PWD}/." "${worktree}/"
    chmod -R u=rwX,go=rX "$worktree"
    cd "$worktree"

    do_cmd build "$@"
;;
push)
    do_cmd push "$@"
;;
pull)
    ./pull-cache-from-images.py "$@"
    docker-compose pull --ignore-pull-failures "$@"
esac
