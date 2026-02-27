#
# Copyright (C) 2026 Hedera Hashgraph, LLC
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
ENV JAVA_VERSION="jdk-25+36"
ENV JAVA_HOME=/usr/local/java
ENV PATH=${JAVA_HOME}/bin:${PATH}

# Define Application Environment Variables
ENV APP_HOME="/opt/hgcapp/services-hedera/HapiApp2.0"
ENV JAVA_HEAP_MIN=""
ENV JAVA_HEAP_MAX=""
ENV JAVA_OPTS=""
ENV JAVA_MAIN_CLASS=""
ENV JAVA_CLASS_PATH=""

## Consensus Node Configuration
ENV CONSENSUS_NODE_ID=""

# Performance Tuning for Malloc
ENV MALLOC_ARENA_MAX=4

# Log Folder Name Override
ENV LOG_DIR_NAME=""
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

ARG S6_OVERLAY_VERSION=3.1.6.2

RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
    /usr/bin/crb enable && \
    dnf -y install \
        binutils \
        libsodium \
        openssl \
        zlib \
        readline \
        tzdata \
        gzip \
        tar \
        xz \
        ca-certificates \
        curl \
        zip \
        unzip \
        sudo && \
    dnf clean all

# Install Java 25 Adoptium JDK
RUN set -eux; \
        ARCH="$(objdump="$(command -v objdump)" && objdump --file-headers "$objdump" | awk -F '[:,]+[[:space:]]+' '$1 == "architecture" { print $2 }')"; \
        case "${ARCH}" in \
           aarch64|arm64) \
             ESUM='95716d04bdfc8b10c94f4448ea8d57a3ba872d98b53c752e4c6b48f1c95bc582'; \
             BINARY_URL='https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25%2B36/OpenJDK25U-jdk_aarch64_linux_hotspot_25_36.tar.gz'; \
             ;; \
          amd64|i386:x86-64) \
            ESUM='ee04de95ab9da7287d40bd2173076ecc2a6dd662f007bedfc6eb0380c0ef90e8'; \
            BINARY_URL='https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25%2B36/OpenJDK25U-jdk_x64_linux_hotspot_25_36.tar.gz'; \
            ;; \
           ppc64el|powerpc:common64) \
             ESUM='b060bb12b3a192a0599f03ebb9495492f78c48cb61e291e336a8b00e7798ffb0'; \
             BINARY_URL='https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25%2B36/OpenJDK25U-jdk_ppc64le_linux_hotspot_25_36.tar.gz'; \
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

# Install s6-overlay with checksum verification
RUN set -eux; \
    ARCH="$(objdump="$(command -v objdump)" && objdump --file-headers "$objdump" | awk -F '[:,]+[[:space:]]+' '$1 == "architecture" { print $2 }')"; \
    case "${ARCH}" in \
        aarch64|arm64) S6_ARCH="aarch64";; \
        amd64|i386:x86-64) S6_ARCH="x86_64";; \
        ppc64el|powerpc:common64) S6_ARCH="ppc64le";; \
        *) echo "Unsupported s6-overlay architecture: ${ARCH}"; exit 1;; \
    esac; \
    NOARCH_URL="https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz"; \
    ARCH_URL="https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz"; \
    curl -LfsSo /tmp/s6-overlay-noarch.tar.xz "${NOARCH_URL}"; \
    curl -LfsSo /tmp/s6-overlay-noarch.tar.xz.sha256 "${NOARCH_URL}.sha256"; \
    curl -LfsSo /tmp/s6-overlay-${S6_ARCH}.tar.xz "${ARCH_URL}"; \
    curl -LfsSo /tmp/s6-overlay-${S6_ARCH}.tar.xz.sha256 "${ARCH_URL}.sha256"; \
    (cd /tmp && sha256sum -c s6-overlay-noarch.tar.xz.sha256); \
    (cd /tmp && sha256sum -c s6-overlay-${S6_ARCH}.tar.xz.sha256); \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz; \
    tar -C / -Jxpf /tmp/s6-overlay-${S6_ARCH}.tar.xz; \
    rm -f /tmp/s6-overlay-noarch.tar.xz /tmp/s6-overlay-noarch.tar.xz.sha256 /tmp/s6-overlay-${S6_ARCH}.tar.xz /tmp/s6-overlay-${S6_ARCH}.tar.xz.sha256

RUN echo >> /etc/sudoers && \
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

# Ensure proper file permissions
RUN chmod -R +x /opt/hgcapp/services-hedera/HapiApp2.0/entrypoint.sh && \
    chown -R 2000:2000 /opt/hgcapp/

RUN mkdir -p /etc/network-node/env && \
    mkdir -p /etc/network-node/startup && \
    mkdir -p /etc/network-node/config && \
    touch /etc/network-node/env/application.env

ADD stage_files.sh /etc/network-node/startup/

RUN chown -R 2000:2000 /etc/network-node && \
    chmod -R +x /etc/network-node/startup/stage_files.sh && \
    chmod -R +x /etc/network-node/env/application.env

# Copy s6 overlay rootfs additions
COPY rootfs/ /

RUN chmod -R +x /etc/cont-init.d /etc/services.d

# Expose TCP/UDP Port Definitions
EXPOSE 50111/tcp 50211/tcp 50212/tcp

# Basic service health check via s6
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD /command/s6-svstat /run/service/network-node | grep -q "up" || exit 1

# Set Final Working Directory and User
WORKDIR "/opt/hgcapp"

ENTRYPOINT ["/init"]
