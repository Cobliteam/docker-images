FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
       openssh-server sudo dbus git-core vim \
       curl iproute2 net-tools ca-certificates \
       bzip2 zip unzip xz-utils \
       apt-transport-https apt-utils \
    && rm -rf /var/lib/apt/lists/*

RUN find /lib/systemd/system/sysinit.target.wants -xtype f -printf '%f\n' | \
    grep -v -E '(journal|machine-id|random-seed|tmpfiles|ldconfig)' | \
    xargs -d'\n' --no-run-if-empty systemctl mask
RUN find /lib/systemd/system -xtype f -printf '%f\n' | \
    grep -E '(udev|dracut|getty)' | \
    xargs -d'\n' --no-run-if-empty systemctl mask
RUN systemctl mask systemd-remount-fs systemd-timesyncd systemd-networkd

RUN systemctl set-default multi-user.target
RUN systemctl enable ssh

RUN useradd -s /bin/bash -m -d /home/test test
RUN printf "Defaults !requiretty\ntest ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/test

EXPOSE 22

ENTRYPOINT ["/sbin/init"]
