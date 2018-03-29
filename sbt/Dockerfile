FROM ubuntu:16.04

RUN apt-get update -q && apt-get install -y git ssh tar gzip ca-certificates apt-transport-https

RUN apt-get update -q && apt-get install -y python3-pip python3-dev python3-wheel

RUN apt-get update -q && apt-get install -y openjdk-8-jdk-headless

RUN echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable" > /etc/apt/sources.list.d/docker.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DC858229FC7DD38854AE2D88D81803C0EBFCD88 && \
    apt-get update -q && \
    apt-get install -y docker-ce

RUN echo "deb https://sbt.bintray.com/debian /" > /etc/apt/sources.list.d/sbt.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 && \
    apt-get update -q && \
    apt-get install -y bc sbt

RUN CASS_DRIVER_NO_CYTHON=1 pip3 install cassandra-migrate

RUN pip3 install awscli

ENV DOCKERIZE_VERSION v0.6.0
RUN wget -q https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz -O- \
    | tar xzv -C /usr/local/bin --owner=root --group==root
