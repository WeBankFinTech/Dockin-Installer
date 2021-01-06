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
#description     :install kubelet/kubeadm/kubectl v1.11.2.
#config file     :install.properties
#author		       :
#linux           :centos7
#user            :root
#==============================================================================
set -ex
current_dir=$(cd "$(dirname "$0")";pwd)

# root
if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi


#
# install.properties
install_config=$1
if [ ! -f ${install_config} ];then
    echo "no such config file ${install_config}"
    exit 1
fi
. ${install_config}

if [ -z "$ip" ]; then
  echo "ip in install.properties is not set";
  exit 1;
fi

if [ 0 =  "$(grep HOSTIP ${install_config} | wc -l)" ]; then echo "ip $ip";
else
  echo "[@HOSTIP] in install.properties is not be replaced";
  exit 1;
fi

#
mkdir -p /data/kubernetes/config;

# hostname
hostname=$(sed 's/\./-/g' <<< $ip);
hostnamectl set-hostname $hostname;

if [ -z "$env" ];
then echo "env not set";
else
    if [ $env == "sit" ];
    then
        hostname=$ip
    fi
fi

# kubelet
rm -rf /data/kubernetes/config/kubelet;
rm -rf /data/kubernetes/config/kubelet-extra-args;
cp -rf $current_dir/kubelet-extra-args /data/kubernetes/config/;

# kubeletIP
sed -i "s/\[HOSTNAME\]/$hostname/g" /data/kubernetes/config/kubelet-extra-args;

# Node ip
sed -i "s/\[IP\]/$ip/g" /data/kubernetes/config/kubelet-extra-args;

