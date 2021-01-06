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
#description     :install kubernetes master v1.16.6.
#author		       :
#linux           :centos7
#user            :root
#config file     :install.properties
#comment         :
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

#
rm -rf tmp/master-config
mkdir -p tmp/master-config

#
cp -f ../../../conf/install.properties ./
. install.properties

# tmp
cp -r ../resources/master-config/kubeadm-config.yaml tmp/master-config/

if [ -z "$env" ];
then echo "env not set";
else
    if [ $env == "uat" ];
    then
        cp -r ../resources/master-config/kubeadm-config-uat.yaml tmp/master-config/kubeadm-config.yaml
    fi
fi

#
log INFO "replace variable, generate config file"

#
if [ -z "$master_vip" ]; then
  log ERROR "master_vip in install.properties is not set";
  exit 1;
fi

if [ -z "$etcd_list" ]; then
  log ERROR "etcd_list in install.properties is not set";
  exit 1;
fi

if [ -z "$master_ip_list" ]; then
  log ERROR "master_ip_list in install.properties is not set";
  exit 1;
fi

if [ -z "$local_ip" ]; then
  log ERROR "local_ip in install.properties is not set";
  exit 1;
fi

# VIP
sed -i "s/\[dockin_MASTER_VIP\]/$master_vip/g" tmp/master-config/kubeadm-config.yaml

#
sed -i "s/\[HOSTIP\]/$local_ip/g" tmp/master-config/kubeadm-config.yaml

# ETCDkubeadm-config.yaml
# http://[dockin_ETCD_IP_1]:2379
IFS=',' read -ra etcd_arr <<< "$etcd_list"
for i in "${etcd_arr[@]}"; do
  etcd_list_dest="${etcd_list_dest}    - ${i}\n"
done

etcd_list_dest=${etcd_list_dest::-2}
sed -i "s#\[dockin_ETCD_LIST\]#$etcd_list_dest#g" tmp/master-config/kubeadm-config.yaml

# master ip
IFS=',' read -ra master_arr <<< "$master_ip_list"
for i in "${master_arr[@]}"; do
  master_ip_list_dest="${master_ip_list_dest}    - ${i}\n"
done

sed -i "s/\[dockin_MASTER_IP_LIST\]/$master_ip_list_dest/g" tmp/master-config/kubeadm-config.yaml


if [ -z "$env" ];
then echo "env not set";
else
    if [ $env == "uat" ];
    then
        sed -i "s/\[ip\]/$local_ip/g"  tmp/master-config/kubeadm-config.yaml;
    fi
fi
