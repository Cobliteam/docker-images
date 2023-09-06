FROM eclipse-temurin:11.0.20.1_1-jdk-jammy

### Datadog agent config
ENV DD_TRACE_ENABLED="false"
ARG DD_REPO_BASE_URL=https://github.com/DataDog/dd-trace-java/releases/download
ARG DD_VERSION=0.110.0

WORKDIR /opt/java-app/

RUN  apt-get update \
  && apt-get install --no-install-recommends -y wget=1.21.2-2ubuntu1 fontconfig=2.13.1-4.2ubuntu5 \
  && wget -O dd-java-agent.jar \
    ${DD_REPO_BASE_URL}/v${DD_VERSION}/dd-java-agent-${DD_VERSION}.jar \
  && apt-get remove --purge -y wget \
  && rm -rf /var/lib/apt/lists/*

ENV JAVA_OPTS="-javaagent:/opt/java-app/dd-java-agent.jar"

LABEL io.buildpacks.stack.id=io.buildpacks.stacks.jammy
