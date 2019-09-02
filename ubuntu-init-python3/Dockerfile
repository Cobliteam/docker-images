ARG UBUNTU_VERSION=18.04
FROM cobli/ubuntu-init:${UBUNTU_VERSION}

RUN apt-get update -q \
    && apt-get install -y --no-install-recommends \
       python3-pip python3-setuptools python3-wheel python3-dev python3-venv \
       build-essential libssl-dev libffi-dev gnupg libz-dev \
    && rm -rf /var/lib/apt/lists/*
