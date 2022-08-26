FROM openjdk:11.0.16-slim-buster

ARG FLINK_VERSION
ARG SCALA_VERSION_MAJOR
ARG SCALA_VERSION_MINOR
ARG DD_VERSION=0.107.1
ARG GOSU_VERSION=1.11
ARG FLINK_HOME=/opt/flink

# Install dependencies
ENV DD_VERSION=$DD_VERSION
RUN set -ex; \
  apt-get update; \
  apt-get -y install wget libsnappy1v5 gnupg jq gettext libjemalloc-dev; \
  rm -rf /var/lib/apt/lists/*; \
  wget -O opt/dd-java-agent.jar \
    https://github.com/DataDog/dd-trace-java/releases/download/v${DD_VERSION}/dd-java-agent-${DD_VERSION}.jar

# Grab gosu for easy step-down from root
ENV GOSU_VERSION=$GOSU_VERSION
RUN set -ex; \
  wget -nv -O /usr/local/bin/gosu \
    https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$(dpkg --print-architecture); \
  wget -nv -O /usr/local/bin/gosu.asc \
    https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$(dpkg --print-architecture).asc; \
  export GNUPGHOME="$(mktemp -d)"; \
  for server in ha.pool.sks-keyservers.net $(shuf -e \
                          hkp://p80.pool.sks-keyservers.net:80 \
                          keyserver.ubuntu.com \
                          hkp://keyserver.ubuntu.com:80 \
                          pgp.mit.edu) ; do \
      gpg --batch --keyserver "$server" --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && break || : ; \
  done && \
  gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
  gpgconf --kill all; \
  rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
  chmod +x /usr/local/bin/gosu; \
  gosu nobody true

# Configure Flink version
ENV FLINK_TGZ_URL=https://archive.apache.org/dist/flink/flink-${FLINK_VERSION}/flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION_MAJOR}.${SCALA_VERSION_MINOR}.tgz \
    FLINK_ASC_URL=https://archive.apache.org/dist/flink/flink-${FLINK_VERSION}/flink-${FLINK_VERSION}-bin-scala_${SCALA_VERSION_MAJOR}.${SCALA_VERSION_MINOR}.tgz.asc

# Prepare environment
ENV FLINK_HOME $FLINK_HOME
ENV PATH=$FLINK_HOME/bin:$PATH
RUN groupadd --system --gid=9999 flink && \
    useradd --system --home-dir $FLINK_HOME --uid=9999 --gid=flink flink
COPY --chown=flink:flink scripts $FLINK_HOME/bin/cobli-scripts
WORKDIR $FLINK_HOME

# Install Flink
RUN set -ex; \
  wget -nv -O flink.tgz "$FLINK_TGZ_URL"; \
  \
  tar -xf flink.tgz --strip-components=1; \
  rm flink.tgz; \
  \
  chown -R flink:flink .;

USER flink

# Configure container
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
EXPOSE 8081 6122 6123 6124 6125
CMD ["help"]
