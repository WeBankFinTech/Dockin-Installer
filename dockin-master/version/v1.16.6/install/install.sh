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
#comment         :HA。install.properties。
#                 ，MasterMaster。
#==============================================================================
set -e
current_dir=$(cd "$(dirname "$0")";pwd)
function log() {
    level=$1
    message=$2
    log="`date +'%Y-%m-%d %H:%M:%S'`,$LINENO [$level] - $message"
    echo $log
}

# 。：。：。
function checking_process(){
  process=$(ps -ef | grep "$1" | grep -v "grep") || true
  if [[ $process == "" ]]; then
      log ERROR "$1 start failed, please check"
      exit 1
  else
      pid=$(echo $process| awk -F ' ' {'print $2'})
      if [[ $pid == "" ]]; then
          log ERROR  "$1 start failed, please check"
          exit 1
      else
          echo $pid
      fi
  fi
}

function usage(){
    echo "install.sh first_node=(true/false)";
    echo "if this master is first node, please input first_node=true, else first_node=false";
}

# first_node
if [ $# == 1 ]; then
    export $1
    if [[ $first_node == "" ]]; then
      usage
      exit 1;
    fi
else
    usage
    exit 1;
fi

# root
if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

# kubelet
if [ ! -f "/usr/bin/kubelet" ]; then
  log ERROR "kubelet is NOT installed, please exec agent install first";
  exit 1;
fi

# kubeadm
if [ ! -f "/bin/kubeadm" ]; then
  log ERROR "kubeadm is NOT installed, please exec agent install first";
  exit 1;
fi

# master
log INFO "checK master installed status."
apiserver_process=$(ps -ef | grep "kube-apiserver" | grep -v "grep") || true
if [[ $apiserver_process == "" ]]; then
    log INFO "master not installed"
else
    log ERROR "master has installed, please uninstall first"
    exit 1
fi

# ，，，，
if [[ $first_node == "false" ]]; then
    # check certificate file
    if [[ $(ls -a /etc/kubernetes/pki/*.crt | wc -l) == "5" && $(ls -a /etc/kubernetes/pki/*.key | wc -l) == "6" && $(ls -a /etc/kubernetes/pki/sa.pub | wc -l) == "1" ]]; then
        log INFO "certificate file exist, skip to generate"
    else
        log ERROR "first_node=false, please copy all certificate file to /etc/kubernetes/pki/ manually"
        exit 1;
    fi
fi


#
./generate_conf.sh

# copy auth files if file not exists
mkdir -p /etc/kubernetes/pki/
if [ ! -f "/etc/kubernetes/pki/basic_auth_file.csv" ]; then
    cp -r ../../../common/basic-auth/basic_auth_file.csv /etc/kubernetes/pki/
fi


#
sed -i 's/.*swap.*/#&/' /etc/fstab
swapoff -a
if [ -d "/proc/sys/net/bridge" ]; then
    echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
fi
systemctl disable firewalld
systemctl stop firewalld
systemctl stop kubelet

#
cd ../resources
rm -rf dockin-package;
tar zxvf dockin-package.tar.gz;
mv *-package dockin-package;


#
log INFO "loading images...";
for i in $(ls ./dockin-package/package/*.tar); do log INFO "loading $i"; docker load --input $i; done

# install kubectl kubeadm kubelet
kube_version="v1.16.6"
binary_dir="dockin-package/binary"

cp -f ${binary_dir}/kubeadm /usr/bin/

cp -f ${binary_dir}/kubectl /usr/bin/

cp -f ${binary_dir}/kubelet /usr/bin/


#
mkdir -p /etc/kubernetes/manifests/

#
mkdir -p /data/logs/kubernetes/

#
kubeadm init --config $current_dir/tmp/master-config/kubeadm-config.yaml --v=4


#
sed -i 's/\/etc\/sysconfig\/kubelet/\/data\/kubernetes\/config\/kubelet-extra-args/g'  /etc/systemd/system/kubelet.service.d/10-kubeadm.conf;

# kubelet
systemctl daemon-reload
systemctl restart kubelet

# kubectl
rm -rf ~/.kube/
mkdir -p ~/.kube/
cp -i /etc/kubernetes/admin.conf ~/.kube/config
log INFO "add kubectl admin config to ~/.kube/"

# 30s，apiserver
sleep 30

# api-server
number_re='^[0-9]+$'
log INFO "checking kube-apiserver process"

if ! [[ "$(checking_process 'kube-apiserver')" =~ $number_re ]] ; then
   log ERROR "kube-apiserver is not start"
else
   log INFO  "kube-apiserver start successfully"
fi

# kube-scheduler
log INFO "checking kube-scheduler process"

if ! [[ "$(checking_process 'kube-scheduler')" =~ $number_re ]] ; then
   log ERROR "kube-scheduler is not start"
else
   log INFO  "kube-scheduler start successfully"
fi

# kube-controller-manager
log INFO "checking kube-controller-manager process"

if ! [[ "$(checking_process 'kube-controller-manager')" =~ $number_re ]] ; then
   log ERROR "kube-controller-manager is not start"
else
   log INFO  "kube-controller-manager start successfully"
fi

# RBAC
kubectl apply -f ${current_dir}/../../../common/ca-update.yaml

# flannel
flannel_yaml=${current_dir}/../../../common/flannel-cni/kube-flannel.yaml
[ -f ../resources/flannel-cni/kube-flannel.yaml ] && flannel_yaml=${current_dir}/../resources/flannel-cni/kube-flannel.yaml

kubectl apply -f ${flannel_yaml}

# core dns
core_dns_yaml=${current_dir}/../../../common/addons/core-dns/core-dns-deployment.yaml
[ -f ../resources/addons/core-dns/core-dns-deployment.yaml ] && core_dns_yaml=${current_dir}/../resources/addons/core-dns/core-dns-deployment.yaml

kubectl apply -f ${core_dns_yaml}

# admin rbac
kubectl apply -f ../../../common/basic-auth/admin-rbac.yaml

cd $current_dir
./renew_certs.sh

# clear dir
rm -rf tmp

rm -rf dockin-package;

exit 0;