#!/usr/bin/env sh

set -e 

if [ ! -d /sbt-cache/sbt-preloaded ]; then
    mkdir /sbt-cache/sbt-preloaded
    cp -r /opt/sbt/lib/local-preloaded/ /sbt-cache/sbt-preloaded
fi

exec "$@"
