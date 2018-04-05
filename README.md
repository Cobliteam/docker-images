# Cobli CI Images

This repository contains specifications for some Docker images used in
Continuous Integration of other Cobli projects. 

All the images are pushed to quay.io automatically. To use them, prefix the
image name with `quay.io`. For example, `quay.io/cobli/ci-sbt:latest`.

## cobli/ci-sbt

Base: ubuntu:16.04

This image contains:
- Base utilities: git, ssh, tar, gzip, ca-certificates, apt-transport-https
- Python3 and dev. dependencies: for cassandra-migrate
- OpenJDK 8 (for SBT)
- The latest SBT launcher from the DEB repository
- [Cassandra-migrate](https://github.com/Cobliteam/cassandra-migrate)
- The AWS CLI

## cobli/ubuntu-init-14-04

Base: ubuntu-upstart:14.04

Ubuntu 14.04 (Trusty) image with Upstart as an init system. A `test` user is
created, and OpenSSH is set up to access it (either by setting a password or
adding some authorized keys with `docker exec`).

Additionally contains:
  - sudo
  - dbus
  - curl
  - git
  - vim
  - some network tools

## cobli/ubuntu-init-16-04

Base: ubuntu:16.04
Ubuntu 16.04 (Xenial) image with systemd as an init service. Similar to the
14.04 image, but with some additional requirements for running it, since
systemd needs some system privilegs to run.

- `/sys/fs/cgroup` must be bind-mounted (possibly RO) from the host system
- `CAP_SYS_ADMIN` must be granted
- `seccomp` must be set to `unconfined`
- Three `tmpfs` mounts must be set up:
  * `/tmp:exec,mode=1777`
  * /run
  * /run/lock
- `stop_signal` must be set to `SIGRTMIN+3`

## cobli/ubuntu-init-python-14-04

Base: ubuntu-init-14-04

Adds Python 2 development packages and some dependencies commonly used for
building Python packages.

## cobli/ubuntu-init-python-16-04

Base: ubuntu-init-16-04

Same as above, but for Ubuntu 16.04.

## cobli/squid-ssl

Base: alpine:3.7

Squid (the caching proxy) image. Meant for use as an explicit proxy (by setting
the `http_proxy` and `https_proxy` env. vars) in other containers.

An ephemeral CA is generated in `/etc/squid/ssl`, which is set up as a volume.
`/etc/squid/ssl/ca.pem` can be copied to other containers and added to their
set of trusted CAs to allow for HTTPS interception.

The cache directory is set to `/var/spool/squid` which is also a volume.

To configure Squid, the following env. vars can be set (with their defaults
shown):

- `SQUID_SSL_DIR=/etc/squid/ssl`
- `SQUID_SSL_DB_DIR=/var/cache/squid/ssl_Db`
- `SQUID_SSL_DB_MEM_SIZE=4MB`
- `SQUID_SSL_DB_DISK_SIZE=16MB`
- `SQUID_CACHE_DIR_MAX_SIZE_MB=1000`
- `SQUID_OBJECT_MAX_SIZE="100 MB"`
- `SQUID_PORT=3128`.

Alternatively, a custom config file can be bind-mounted to
`/etc/squid/squid.conf` while passing `SQUID_CUSTOM_CONFIG=1` as an env var.
