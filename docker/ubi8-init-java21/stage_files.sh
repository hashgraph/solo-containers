#!/usr/bin/env bash

########################################################################################################################
# Copyright 2016-2025 Hedera Hashgraph, LLC                                                                            #
#                                                                                                                      #
# Licensed under the Apache License, Version 2.0 (the "License");                                                      #
# you may not use this file except in compliance with the License.                                                     #
# You may obtain a copy of the License at                                                                              #
#                                                                                                                      #
#     http://www.apache.org/licenses/LICENSE-2.0                                                                       #
#                                                                                                                      #
# Unless required by applicable law or agreed to in writing, software                                                  #
# distributed under the License is distributed on an "AS IS" BASIS,                                                    #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.                                             #
# See the License for the specific language governing permissions and                                                  #
# limitations under the License.                                                                                       #
########################################################################################################################

set -eo pipefail
files=$(ls -1 /etc/network-node/config)
for file in $files; do
  if [ -f "/opt/hgcapp/services-hedera/HapiApp2.0/${file}" ]; then
  rm -f "/opt/hgcapp/services-hedera/HapiApp2.0/${file}"
  fi
ln -s "/etc/network-node/config/${file}" "/opt/hgcapp/services-hedera/HapiApp2.0/${file}"

# copy hedera.crt and hedera.key to /opt/hgcapp/services-hedera/HapiApp2.0/
cp /shared-hapiapp/hedera.* /opt/hgcapp/services-hedera/HapiApp2.0/
done
