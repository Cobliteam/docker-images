# syntax=docker/dockerfile:experimental

FROM openjdk:8-stretch

ARG SBT_VERSION=1.2.8

# Make sure SSH doesnt't prompt for host keys
RUN printf '%s\n' 'UserKnownHostsFile /dev/null' 'StrictHostKeyChecking no' \
    >> /etc/ssh/ssh_config

# Install SBT
ENV SBT_VERSION=${SBT_VERSION}
RUN mkdir /opt/sbt \
    && curl -sSL https://piccolo.link/sbt-${SBT_VERSION}.tgz \
       | tar xz --strip-components=1 -C /opt/sbt \
    && ln -s /opt/sbt/bin/sbt /usr/local/bin/sbt

RUN mkdir -p /etc/sbt /sbt-cache \
    && printf '%s\n' \
       -ivy /sbt-cache/ivy2 \
       -sbt-boot /sbt-cache/sbt-boot \
       -Dsbt.preloaded=/sbt-cache/sbt-preloaded \
       -Dcoursier.cache=/sbt-cache/coursier \
       > /etc/sbt/sbtopts

RUN mkdir -p /sbt-cache/sbt-preloaded \
    && cp -r /opt/sbt/lib/local-preloaded/. /sbt-cache/sbt-preloaded/

ONBUILD RUN \
    --mount=type=bind,source=./,target=/run/src \
    --mount=type=secret,id=aws,target=/root/.aws/credentials \
    --mount=type=ssh \
    cd /run/src \
    && sbt update

VOLUME ["/sbt-cache"]

CMD ["sbt"]
