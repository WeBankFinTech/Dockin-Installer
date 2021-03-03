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
#description     :install kubelet/kubeadm/kubectl v1.16.6.
#config file     :install.properties
#author		       :
#linux           :centos7
#user            :root
#==============================================================================
set -ex
current_dir=$(cd "$(dirname "$0")";pwd)
common_dir=${current_dir}/../../../common
install_config=${current_dir}/../../../conf/install.properties
cni_dir=${current_dir}/../../../cni

function log() {
    level=$1
    message=$2
    log="`date +'%Y-%m-%d %H:%M:%S'`,$LINENO [$level] - $message"
    echo $log
}

# root
if [ $UID -ne 0 ]; then
    log ERROR "Superuser privileges are required to run this script."
    log ERROR "e.g. \"sudo $0\""
    exit 1
fi

# docker /usr/bin/dockerd
if [ ! -f "/usr/bin/dockerd" ]; then
  log ERROR "dockerd not found";
  exit 1;
fi

#
# install.properties
. $install_config
if [ -z "$ip" ]; then
  log INFO "ip in install.properties is not set";
  exit 1;
fi

if [ 0 =  "$(grep HOSTIP $install_config | wc -l)" ]; then log INFO "ip $ip";
else
  log ERROR "[@HOSTIP] in install.properties is not be replaced";
  exit 1;
fi


#
cd ../resources
rm -rf dockin-package;
tar zxvf dockin-package.tar.gz;
mv *-package dockin-package;


#
log INFO "loading images...";
for i in $(ls ./dockin-package/package/*.tar); do log INFO "loading $i"; docker load --input $i; done

# install kubectl kubeadm kubelet
binary_dir="dockin-package/binary"

cp -f ${binary_dir}/kubeadm /usr/bin/
cp -f ${binary_dir}/kubectl /usr/bin/
cp -f ${binary_dir}/kubelet /usr/bin/

# create service
cp -f $common_dir/systemd/kubelet.service /etc/systemd/system/
cp -rf $common_dir/systemd/kubelet.service.d /etc/systemd/system/

systemctl daemon-reload

#
mkdir -p /data/logs/kubernetes;

#
mkdir -p /data/kubernetes/config;

# hostname
hostname=$(sed 's/\./-/g' <<< $ip);
hostnamectl set-hostname $hostname;

#
rm -rf /data/kubernetes/config/kubelet

# kubelet
$common_dir/kubelet_args_set/generate_kubelet_extra_args.sh ${install_config}

# ，
rm -rf /etc/sysconfig/kubelet

# install cni plugin bin
mkdir -p /opt/cni/bin

cd $cni_dir/common/cni-plugins
tar zxvf cni-plugins-amd64-v0.6.0.tgz -C /opt/cni/bin
chmod +x /opt/cni/bin/*

systemctl daemon-reload;
systemctl restart kubelet && systemctl enable kubelet;