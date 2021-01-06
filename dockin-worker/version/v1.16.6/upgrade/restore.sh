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

#==============================================================================
#description     :upgrade kubernetes cluster to 1.12.5.
#author		     :
#linux           :centos7
#user            :root
#config file     :install.properties
#comment         :master，
#==============================================================================
set -e

function log() {
    level=$1
    message=$2
    log="`date +'%Y-%m-%d %H:%M:%S'`,$LINENO [$level] - $message"
    echo $log
}

# root
if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

# restore manifests files
log INFO "please restore files manually, because automatic file replacement is dangerous. see backup.sh"

# backup manifests files
log INFO "restore /data/kubernetes config..."
cp -r config/* /data/kubernetes/config/

log INFO "restore /etc/kubernetes/"
cp -r etc/kubernetes/*  /etc/kubernetes/

log INFO "restore /var/lib/kubelet/config.yaml..."
cp -r var/lib/kubelet/config.yaml /var/lib/kubelet/

log INFO "restore cni plugins..."
cp -r cni/* /etc/cni/net.d/*

log INFO "restore kubelet/kubeadm/kubectl binary files and unzip..."
tar zxvfP binary.tar.gz

systemctl stop kubelet

cp -r binary/* /usr/bin/

systemctl restart kubelet
