#
# Copyright (C) 2023 Hedera Hashgraph, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FROM registry.access.redhat.com/ubi8/ubi-init:latest
# Define Standard Environment Variables
ENV LC_ALL=C.UTF-8

# Define JDK Environment Variables
ENV JAVA_VERSION "jdk-21.0.7+6"
ENV JAVA_HOME /usr/local/java
ENV PATH ${JAVA_HOME}/bin:${PATH}

# Define Application Environment Variables
ENV APP_HOME="/opt/hgcapp/services-hedera/HapiApp2.0"
ENV JAVA_HEAP_MIN=""
ENV JAVA_HEAP_MAX=""
ENV JAVA_OPTS=""
ENV JAVA_MAIN_CLASS ""
ENV JAVA_CLASS_PATH ""

## Consensus Node Configuration
ENV CONSENSUS_NODE_ID=""

# Performance Tuning for Malloc
ENV MALLOC_ARENA_MAX 4

# Log Folder Name Override
ENV LOG_DIR_NAME ""

RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    /usr/bin/crb enable && \
    dnf -y install binutils libsodium openssl zlib readline tzdata gzip tar ca-certificates curl zip unzip && \
    dnf clean all

# Install zip and unzip
RUN dnf -y install zip unzip && \
    dnf clean all

# Install Java 21 Adoptium JDK
RUN set -eux; \
        ARCH="$(objdump="$(command -v objdump)" && objdump --file-headers "$objdump" | awk -F '[:,]+[[:space:]]+' '$1 == "architecture" { print $2 }')"; \
        case "${ARCH}" in \
           aarch64|arm64) \
             ESUM='31dba70ba928c78c20d62049ac000f79f7a7ab11f9d9c11e703f52d60aa64f93'; \
             BINARY_URL='https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.7%2B6/OpenJDK21U-jdk_aarch64_linux_hotspot_21.0.7_6.tar.gz'; \
             ;; \
          amd64|i386:x86-64) \
            ESUM='974d3acef0b7193f541acb61b76e81670890551366625d4f6ca01b91ac152ce0'; \
            BINARY_URL='https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.7%2B6/OpenJDK21U-jdk_x64_linux_hotspot_21.0.7_6.tar.gz'; \
            ;; \
           ppc64el|powerpc:common64) \
             ESUM='2ddc0dc14b07d9e853875aac7f84c23826fff18b9cea618c93efe0bcc8f419c2'; \
             BINARY_URL='https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.7%2B6/OpenJDK21U-jdk_ppc64le_linux_hotspot_21.0.7_6.tar.gz'; \
             ;; \
           *) \
             echo "Unsupported architecture: ${ARCH}"; \
             exit 1; \
             ;; \
        esac; \
    curl -LfsSo /tmp/openjdk.tar.gz ${BINARY_URL}; \
    echo "${ESUM} */tmp/openjdk.tar.gz" | sha256sum -c -; \
    mkdir -p /usr/local/java; \
    tar --extract \
    	      --file /tmp/openjdk.tar.gz \
    	      --directory "/usr/local/java" \
    	      --strip-components 1 \
    	      --no-same-owner \
    	  ; \
    rm -f /tmp/openjdk.tar.gz /usr/local/java/lib/src.zip;

RUN dnf -y install sudo && \
    echo >> /etc/sudoers && \
    echo "%hedera ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure the standard user account
RUN groupadd --gid 2000 hedera && \
    useradd --no-user-group --create-home --uid 2000 --gid 2000 --shell /bin/bash hedera && \
    mkdir -p /opt/hgcapp && \
    chown -R hedera:hedera /opt/hgcapp

# Create Application Folders
RUN mkdir -p "/opt/hgcapp" && \
    mkdir -p "/opt/hgcapp/accountBalances" && \
    mkdir -p "/opt/hgcapp/eventsStreams" && \
    mkdir -p "/opt/hgcapp/recordStreams" && \
    mkdir -p "/opt/hgcapp/services-hedera" && \
    mkdir -p "/opt/hgcapp/services-hedera/HapiApp2.0" && \
    mkdir -p "/opt/hgcapp/services-hedera/HapiApp2.0/data" && \
    mkdir -p "/opt/hgcapp/services-hedera/HapiApp2.0/data/apps" && \
    mkdir -p "/opt/hgcapp/services-hedera/HapiApp2.0/data/config" && \
    mkdir -p "/opt/hgcapp/services-hedera/HapiApp2.0/data/keys" && \
    mkdir -p "/opt/hgcapp/services-hedera/HapiApp2.0/data/lib" && \
    mkdir -p "/opt/hgcapp/services-hedera/HapiApp2.0/data/stats" && \
    mkdir -p "/opt/hgcapp/services-hedera/HapiApp2.0/data/saved" && \
    mkdir -p "/opt/hgcapp/services-hedera/HapiApp2.0/data/tmp" && \
    mkdir -p "/opt/hgcapp/services-hedera/HapiApp2.0/data/upgrade" && \
    mkdir -p "/opt/hgcapp/services-hedera/HapiApp2.0/output"

# Add the entrypoint script and systemd service file
ADD entrypoint.sh /opt/hgcapp/services-hedera/HapiApp2.0/
ADD network-node.service /usr/lib/systemd/system/

# Ensure proper file permissions
RUN chmod -R +x /opt/hgcapp/services-hedera/HapiApp2.0/entrypoint.sh && \
    chown -R 2000:2000 /opt/hgcapp/

RUN mkdir -p /etc/network-node && \
    touch /etc/network-node/application.env && \
    chown -R 2000:2000 /etc/network-node

RUN mkdir -p /etc/network-node/startup && \
    chown -R 2000:2000 /etc/network-node/startup && \
    mkdir -p /etc/network-node/config && \
    chown -R 2000:2000 /etc/network-node/config
ADD stage_files.sh /etc/network-node/startup
RUN chmod -R +x /etc/network-node/startup/stage_files.sh

# Expose TCP/UDP Port Definitions
EXPOSE 50111/tcp 50211/tcp 50212/tcp

# Set Final Working Directory and User
WORKDIR "/opt/hgcapp"
