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
#comment         :master
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

# backup manifests files
backuptime=`date +'%Y%m%d%H%M%S'`
mkdir -p /data/kubernetes/backup/$backuptime/
log INFO "backup dir is /data/kubernetes/backup/$backuptime/"

log INFO "backup /data/kubernetes/config config..."
mkdir -p /data/kubernetes/backup/$backuptime/config
cp -r /data/kubernetes/config/* /data/kubernetes/backup/$backuptime/config


log INFO "backup /etc/kubernetes files..."
mkdir -p /data/kubernetes/backup/$backuptime/etc/kubernetes;
cp -r /etc/kubernetes/*  /data/kubernetes/backup/$backuptime/etc/kubernetes;

log INFO "backup kubelet service..."
mkdir -p /data/kubernetes/backup/$backuptime/kubelet.service.d
cp -r /etc/systemd/system/kubelet.service.d/* /data/kubernetes/backup/$backuptime/kubelet.service.d

log INFO "backup kubelet/kubeadm/kubectl binary files and zip..."
mkdir -p /data/kubernetes/backup/$backuptime/binary
cp -r /usr/bin/kubectl /data/kubernetes/backup/$backuptime/binary
cp -r /usr/bin/kubeadm /data/kubernetes/backup/$backuptime/binary
cp -r /usr/bin/kubelet /data/kubernetes/backup/$backuptime/binary

tar zcvfP /data/kubernetes/backup/$backuptime/binary.tar.gz /data/kubernetes/backup/$backuptime/binary
rm -rf /data/kubernetes/backup/$backuptime/binary

# copy restore scripts
cp -r restore.sh /data/kubernetes/backup/$backuptime/



