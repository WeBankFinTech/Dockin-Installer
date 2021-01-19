#!/bin/bash
#
# Copyright (C) @2020 Webank Group Holding Limited
# <p>
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
# <p>
# http://www.apache.org/licenses/LICENSE-2.0
# <p>
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#

################################
# add etcd node
################################
set -e
APP_BIN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_HOME="$(dirname $APP_BIN)"; [ -d "$APP_HOME" ] || { echo "ERROR dockin-etcd failed to detect APP_HOME."; exit 1;}
APP_NAME=$(basename "$APP_HOME")
rm -rf *.pem
./cfssl gencert -initca ca-csr.json | ./cfssljson -bare ca
./cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server server.json | ./cfssljson -bare server
cp server.json member.json
./cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer member.json | ./cfssljson -bare member
./cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | ./cfssljson -bare client

time=$(date "+%m%d%H%M")
tar -czvf cers_$time.tar.gz *.pem
