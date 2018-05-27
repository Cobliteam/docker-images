FROM ubuntu:16.04

RUN apt-get update -q \
    && apt-get install -y --no-install-recommends git tar gzip ca-certificates apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -q \
    && apt-get install -y --no-install-recommends openjdk-8-jdk-headless \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update -q \
    && apt-get install -y --no-install-recommends python3-pip python3-setuptools python3-wheel \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install awscli

RUN echo "deb https://sbt.bintray.com/debian /" > /etc/apt/sources.list.d/sbt.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
    apt-get update -q && \
    apt-get install -y bc sbt

ARG SBT_VERSION
RUN cd /tmp; sbt -sbt-version "$SBT_VERSION" sbtVersion
WORKDIR /root
CMD ["sbt", "-sbt-version", "$SBT_VERSION"]

ARG SOURCE_COMMIT
LABEL org.label-schema.schema-version 1.0
LABEL org.label-schema.version "$SBT_VERSION"
LABEL org.label-schema.vcs-url "https://github.com/Cobliteam/ci-images"
LABEL org.label-schema.vcs-ref "$SOURCE_COMMIT"
