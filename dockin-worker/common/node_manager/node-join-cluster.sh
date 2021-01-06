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
#description     :node join to cluster v1.13.x.
#config file     :install.properties
#author		       :
#linux           :centos7
#user            :root
#==============================================================================
set -ex

# root
if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

#
# upgrade.properties
install_config=$1
if [ ! -f ${install_config} ];then
    echo "no such config file ${install_config}"
    exit 1
fi
. ${install_config}
if [ -z "$ip" ]; then
  echo "ip in upgrade.properties is not set";
  exit 1;
fi

if [ 0 =  "$(grep HOSTIP ${install_config} | wc -l)" ]; then echo "ip $ip";
else
  echo "[@HOSTIP] in upgrade.properties is not be replaced";
  exit 1;
fi

# Master
if [ -z "$master" ]; then
  echo "master in upgrade.properties is not set";
  exit 1;
fi

if [ 0 =  "$(grep MASTER_VIP ${install_config} | wc -l)" ]; then echo "master ip $master";
else
  echo "[@IDC_dockin_MASTER_VIP] in upgrade.properties is not be replaced";
  exit 1;
fi

# token
if [ -z "$token" ]; then
  echo "token in upgrade.properties is not set";
  exit 1;
fi

# kubelet
if [ ! -f "/usr/bin/kubelet" ]; then
  echo "kubelet is NOT installed, please exec agent install first";
  exit 1;
fi

# kubeadm
if [ ! -f "/bin/kubeadm" ]; then
  echo "kubeadm is NOT installed, please exec agent install first";
  exit 1;
fi

#
#echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
#echo '1' >  /proc/sys/net/ipv4/ip_forward

#sed -i 's/.*swap.*/#&/' /etc/fstab
#swapoff -a

#systemctl disable firewalld
#systemctl stop firewalld


#
if [ -z "$env" ];
then
kubeadm join $master:6443 --token=$token --discovery-token-unsafe-skip-ca-verification;
else
    if [ $env == "sit" ];
    then
        kubeadm join $master:6443 --token=$token --discovery-token-unsafe-skip-ca-verification --node-name=$ip;
    fi
fi

# apiserverVIP
sed -i "/server\:/c\    server\: https\:\/\/$master:6443" /etc/kubernetes/kubelet.conf

# kubelet
systemctl daemon-reload
systemctl restart kubelet

sleep 20;

echo "check kubelet service status."
kubelet_process=$(ps -ef | grep "/usr/bin/kubelet" | grep -v "grep") || true
if [[ $kubelet_process == "" ]]; then
    echo "kubelet start failed, please check"
    exit 1
else
    pid=$(echo $kubelet_process| awk -F ' ' {'print $2'})
    if [[ $pid == "" ]]; then
        echo "kubelet start failed, please check"
        exit 1
    else
        echo "kubelet start sucessfully, pid=$pid"
    fi
fi
exit 0;
