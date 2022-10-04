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

## cobli/flink

Base: flink

Current building args:
- FLINK_VERSION=1.9
- SCALA_VERSION_MAJOR=2
- SCALA_VERSION_MINOR=11
- FLINK_HOME=/opt/flink

This is a _Flink_ image with some extra scripts to handle start/stop using
savepoints automatically. These scripts assume that we are deploying a
cluster with a single job, using H.A. mode backed by Zookeeper and storing
savepoints in local directory.

The preStop script will do best effort to create a savepoint, but in some cases
the savepoint reference file cannot be generated. In these cases the start
script will not clean zookeeper data allowing a restart from checkpoints.

In order to use these scrypts you should start jobmanager using the
jobmanager-entrypoint.sh  script and start taskmanagers using the
taskmanager-entrypoint.sh script.

To stop the cluster you should stop jobmanager first using the
jobmanager-prestop-hook.sh script.

All scripts will be present on `$FLINK_HOME/bin/cobli-scripts`

**WARNING**

To configure these scripts you need to set FLINK_CONF_* environment variables,
COBLI_FLINK_* environment variables and COBLI_ENTRYPOINT_* environment
variables.

| Variable | Required | Default Value | Description |
| -------- | -------- | ------------- | ----------- |
| FLINK_CONF_HIGH_AVAILABILITY_ZOOKEEPER_QUORUM | true | Null | The ZooKeeper quorum to use, when running Flink in a high-availability mode with ZooKeeper |
| FLINK_CONF_HIGH_AVAILABILITY_CLUSTER_ID | true | Null | The ID of the Flink cluster, used to separate multiple Flink clusters from each other |
| FLINK_CONF_JOBMANAGER_RPC_ADDRESS | true | Null | The config parameter defining the network address to connect to for communication with the job manager. Scripts use this address to reach REST API |
| FLINK_CONF_REST_PORT | true | Null | The config parameter defining the network port to connect to for communication with the job manager. Scripts use this port to reach REST API |
| FLINK_CONF_STATE_CHECKPOINTS_DIR | false | /mnt/${FLINK_CONF_HIGH_AVAILABILITY_CLUSTER_ID}-states/checkpoints | The default directory used for storing the data files and meta data of checkpoints in a Flink supported filesystem. The storage path must be accessible from all participating processes/nodes(i.e. all TaskManagers and JobManagers) |
| FLINK_CONF_STATE_SAVEPOINTS_DIR | false | /mnt/${FLINK_CONF_HIGH_AVAILABILITY_CLUSTER_ID}-states/savepoints | The default directory for savepoints. Used by the state backends that write savepoints to file systems (MemoryStateBackend, FsStateBackend, RocksDBStateBackend) |
| FLINK_CONF_HIGH_AVAILABILITY_STORAGEDIR | false |/mnt/${FLINK_CONF_HIGH_AVAILABILITY_CLUSTER_ID}-states/zookeeper | File system path (URI) where Flink persists metadata in high-availability setups |
| FLINK_CONF_HIGH_AVAILABILITY_ZOOKEEPER_PATH_ROOT | false | /flink | The root path under which Flink stores its entries in ZooKeeper. |
| COBLI_FLINK_CONF_TEMPLATE_PATH | false | None | If this variable has a non-null value entrypoint scripts will envsubst the template and place the result as the $FLINK_HOME/conf/flink-conf.yaml |
| COBLI_ENTRYPOINT_TIMEOUT_IN_SECS | false | 300 | Max time in seconds to wait for get a successfull completed checkpoint before crash |
| COBLI_ENTRYPOINT_INTERVAL_IN_SECS | false | 5 | Time to wait between two consecutive API requests for number of chekpoints completed |
