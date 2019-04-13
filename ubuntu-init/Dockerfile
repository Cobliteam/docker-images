ARG UBUNTU_VERSION=18.04
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
       systemd libpam-systemd \
       openssh-server sudo dbus git-core vim \
       curl iproute2 net-tools ca-certificates \
       bzip2 zip unzip xz-utils \
       apt-transport-https apt-utils \
    && rm -rf /var/lib/apt/lists/*

# Mask services that should never run in containers
RUN systemctl mask \
    ondemand.service \
    kmod-static-nodes.service \
    systemd-modules-load.service \
    systemd-remount-fs.service \
    systemd-sysctl.service \
    systemd-tmpfiles-setup-dev.service

# Disable all other non-essential services by default with a customnpreset
COPY 50-docker.preset /etc/systemd/system-preset/50-docker.preset
RUN systemctl preset-all && systemctl set-default multi-user.target

RUN useradd -s /bin/bash -m -d /home/test test
RUN printf "Defaults !requiretty\ntest ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/test

EXPOSE 22

ENV container=docker
ENTRYPOINT ["/lib/systemd/systemd"]
