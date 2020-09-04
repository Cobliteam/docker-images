ARG FLINK_VERSION
ARG SCALA_VERSION_MAJOR
ARG SCALA_VERSION_MINOR
ARG BASE_IMAGE=flink:$FLINK_VERSION-scala_$SCALA_VERSION_MAJOR.$SCALA_VERSION_MINOR

ARG FLINK_HOME=/opt/flink

FROM $BASE_IMAGE
USER root
WORKDIR /opt/flink
RUN apt-get update \
      && apt-get install -y --no-install-recommends jq gettext \
      && rm -rf /var/lib/apt/lists/*
COPY --chown=flink:flink scripts $FLINK_HOME/bin/cobli-scripts
EXPOSE 8081 6122 6123 6124 6125
USER flink
