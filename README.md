# Cobli CI Images

This repository contains specifications for some Docker images used in Continuous Integration of other Cobli projects. All of the images are based on Ubuntu.

## cobli/ci-sbt

This image contains:
- Base utilities: git, ssh, tar, gzip, ca-certificates, apt-transport-https
- Python3 and dev. dependencies: for cassandra-migrate
- OpenJDK 8 (for SBT)
- The latest SBT launcher from the DEB repository
- [Cassandra-migrate](https://github.com/Cobliteam/cassandra-migrate)
- The AWS CLI

## cobli/ubuntu-init

Ubuntu images made to run the original init systems of the corresponding
versions (upstart for 14.04 and earlier, systemd for later) with clean
settings for use in containers. OpenSSH is enabled and used for accessing the
containers.

To use the systemd images, some tweaks to the containers are necessary:

- `/sys/fs/cgroup` must be bind-mounted from the host system (even if RO)
- `CAP_SYS_ADMIN` must be granted
- `seccomp` must be set to `unconfined`
- Three `tmpfs` mounts must be set up:
  * `/tmp:exec,mode=1777`
  * /run
  * /run/lock
- `stop_signal` must be set to `SIGRTMIN+3`

These images also contain:
- sudo, dbus, curl, git, vim, some network tools

Available tags:
- `16.04`
- `14.04`

## cobli/ubuntu-init-python

Based on `cobli/ubuntu-init`, but addding Python2 and some development packages
to install/build other Python packages.

Contains:
- pip, setuptools, wheel, python-dev
- build-essential, libffi-dev
