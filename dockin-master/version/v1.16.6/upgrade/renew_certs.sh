#!/usr/bin/env bash

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

if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

./generate_conf.sh

kubeadm alpha certs check-expiration --config=tmp/master-config/kubeadm-config.yaml

kubeadm alpha certs renew admin.conf
kubeadm alpha certs renew apiserver
kubeadm alpha certs renew apiserver-kubelet-client
kubeadm alpha certs renew controller-manager.conf
kubeadm alpha certs renew front-proxy-client
kubeadm alpha certs renew scheduler.conf


kubeadm alpha certs check-expiration --config=tmp/master-config/kubeadm-config.yaml
