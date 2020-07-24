FROM openjdk:11.0.7-jre-slim-buster

### Datadog agent config
ENV DD_TRACE_ENABLED="false"
ARG DD_REPO_BASE_URL=https://repository.sonatype.org/service/local/repositories
ARG DD_VERSION=0.56.0

WORKDIR /opt/java-app/

RUN  apt-get update \
  && apt-get install --no-install-recommends -y wget=1.20.1-1.1 \
  && wget -O dd-java-agent.jar \
    ${DD_REPO_BASE_URL}/central-proxy/content/com/datadoghq/dd-java-agent/${DD_VERSION}/dd-java-agent-${DD_VERSION}.jar \
  && apt-get remove --purge -y wget \
  && rm -rf /var/lib/apt/lists/*

ENV JAVA_OPTS="-javaagent:/opt/java-app/dd-java-agent.jar"

LABEL io.buildpacks.stack.id=io.buildpacks.stacks.bionic"

