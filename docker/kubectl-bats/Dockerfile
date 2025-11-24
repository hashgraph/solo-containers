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

FROM dtzar/helm-kubectl:latest

ENV BATS_HOME=/bats

# switch to root
USER root

RUN apk update && \
    apk add --no-cache \
        curl \
        git \
        vim \
        python3 \
        py3-pip \
        jq \
        bash \
        sudo \
        shadow && \
    git clone --depth=1 https://github.com/bats-core/bats-core.git "${BATS_HOME}/bats-core" && \
    git clone --depth=1 https://github.com/bats-core/bats-support.git "${BATS_HOME}/test_helper/bats-support" && \
    git clone --depth=1 https://github.com/bats-core/bats-assert.git "${BATS_HOME}/test_helper/bats-assert" && \
    curl -L https://github.com/mikefarah/yq/releases/download/v4.34.2/yq_linux_amd64 \
      -o /usr/bin/yq && chmod +x /usr/bin/yq

# Create user 1001 with a shell and home directory
RUN adduser -D -u 1001 -s /bin/bash user && \
    usermod -aG root user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \

# switch to user 1001
USER 1001
