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
#description     :upgrade kubernetes Node to 1.16.6.
#author          
#linux           :centos7
#user            :root
#config file     :install.properties
#comment         :
#==============================================================================
set -e
current_dir=$(cd "$(dirname "$0")";pwd)
upgrade_config=${current_dir}/../../../common/upgrade_conf/upgrade.properties
common_dir=${current_dir}/../../../common
install_config=${current_dir}/../../../conf/install.properties

function log() {
    level=$1
    message=$2
    log="`date +'%Y-%m-%d %H:%M:%S'`,$LINENO [$level] - $message"
    echo $log
}

if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

log INFO "decompressing install package"
cd ../resources
rm -rf dockin-package;
tar zxvf dockin-package.tar.gz;

log INFO "loading images...";
for i in $(ls ./dockin-package/package/*.tar); do log INFO "loading $i"; docker load --input $i; done

# backup
$current_dir/backup.sh

#echo "1" >/proc/sys/net/bridge/bridge-nf-call-iptables

kube_version="v1.16.6"
binary_dir="dockin-package/binary"

# generate custom args
# $common_dir/kubelet_args_set/generate_kubelet_extra_args.sh ${install_config}
# rm -rf /etc/sysconfig/kubelet
# rm -rf /data/kubernetes/config/kubelet

# systemctl daemon-reload;
# systemctl restart kubelet && systemctl enable kubelet;

# upgrade kubeadm
cp -f ${binary_dir}/kubeadm /usr/bin/

kubeadm upgrade node

# upgrade kubelet and kubectl
systemctl stop kubelet

cp -f ${binary_dir}/kubectl /usr/bin/

cp -f ${binary_dir}/kubelet /usr/bin/

systemctl daemon-reload;
systemctl restart kubelet && systemctl enable kubelet;

rm -rf dockin-package binary package
