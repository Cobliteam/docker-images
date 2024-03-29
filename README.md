# Cobli CI Images

**WARNING** This is a public repository and should not contain confidential
data

This repository contains specifications for some **public** Docker
images used as base for some Cobli projects.

All the images are pushed to quay.io automatically. To use them, prefix the
image name with `quay.io`. For example, `quay.io/cobli/ci-sbt:latest`.

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

## cobli/jdk11-datadog-agent

Base: openjdk:11.0.16-jre-slim-buster

This is a _Java_ image with the datadog agent configured

It downloads the datadog agent and adds it to the _JAVA_OPTS_ environment variable.
You can override the _JAVA_OPTS_, but remember to configure the agent by adding the parameter: `-javaagent:/opt/java-app/dd-java-agent.jar`.

To configure the DataDog agent, you need to set its environment variables. For example:
- `DD_ENV: prod`
- `DD_TRACE_ENABLED: "false"`
- `DD_AGENT_HOST: ${YOUR_AGENT_HOST_URL}`
- `DD_SERVICE: ${YOUR_SERVICE_NAME}`
