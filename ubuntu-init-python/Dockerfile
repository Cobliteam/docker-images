ARG UBUNTU_VERSION=18.04
FROM cobli/ubuntu-init:${UBUNTU_VERSION}

RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
       python-pip python-setuptools python-wheel python-dev build-essential \
       libssl-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*
