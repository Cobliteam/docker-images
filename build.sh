#!/usr/bin/env bash

set -e

apt_proxy_addr=
if pgrep -n apt-cacher-ng >/dev/null 2>&1; then
    case "$(uname)" in
    Darwin)
        apt_proxy_addr="192.168.65.1"
    ;;
    Linux)
        apt_proxy_addr=$(ip route get 8.8.8.8 | grep -o 'src.*' | cut -d' ' -f2)
    esac
fi

docker_build() {
    if [ -n "$apt_proxy_addr" ]; then
        docker build --build-arg http_proxy="http://$apt_proxy_addr:3142" "$@"
    else
        docker build "$@"
    fi
}

help() {
    echo "Usage: $0 [build|push] <image> [tag]" >&2
    exit 1
}

if [ $# -lt 2 ]; then
    help
fi

cmd="$1"
image="$2"
tag="$3"

if [ -z "$DOCKER_REPO" ]; then
    DOCKER_REPO=cobli
fi

if [ -z "$tag" ]; then
    tag=latest
fi

composite_tag() {
    if [ "$tag" == "latest" ]; then
        echo "$1"
    else
        echo "$1-${tag}"
    fi
}

case "$cmd" in
build)
    case "$image" in
    ubuntu-init)
        pushd ubuntu-init
        docker_build --build-arg UBUNTU_VERSION=14.04 -f Dockerfile-14.04 \
            -t "${DOCKER_REPO}/ubuntu-init:$(composite_tag 14.04)" .
        docker_build --build-arg UBUNTU_VERSION=16.04 -f Dockerfile \
            -t "${DOCKER_REPO}/ubuntu-init:$(composite_tag 16.04)" .
        docker_build --build-arg UBUNTU_VERSION=18.04 -f Dockerfile \
            -t "${DOCKER_REPO}/ubuntu-init:$(composite_tag 18.04)" .
        popd
    ;;
    ubuntu-init-python)
        pushd ubuntu-init-python
        docker_build --build-arg UBUNTU_VERSION=14.04 -f Dockerfile-14.04 \
            -t "${DOCKER_REPO}/ubuntu-init-python:$(composite_tag 14.04)" .
        docker_build --build-arg UBUNTU_VERSION=16.04 -f Dockerfile \
            -t "${DOCKER_REPO}/ubuntu-init-python:$(composite_tag 16.04)" .
        docker_build --build-arg UBUNTU_VERSION=18.04 -f Dockerfile \
            -t "${DOCKER_REPO}/ubuntu-init-python:$(composite_tag 18.04)" .
        popd
    ;;
    squid-ssl)
        pushd squid-ssl
        docker_build -t "${DOCKER_REPO}/squid-ssl:${tag}" .
        popd
    ;;
    ci-sbt)
        pushd sbt
        docker_build -t "${DOCKER_REPO}/ci-sbt:${tag}" .
        popd
    ;;
    *)
        echo "Unknown image $image" >&2
        exit 1
    esac
;;
push)
    tags=("${tag}")
    if [[ "$image" == ubuntu-* ]]; then
        tags=("$(composite_tag 14.04)" \
              "$(composite_tag 16.04)" \
              "$(composite_tag 18.04)")
    fi

    for tag in "${tags[@]}"; do
        docker push "${DOCKER_REPO}/${image}:${tag}"
    done
;;
*)
    help
esac



