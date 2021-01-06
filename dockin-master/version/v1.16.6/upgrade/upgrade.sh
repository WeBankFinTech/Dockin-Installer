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
#description     :upgrade kubernetes cluster to 1.16.6.
#author          
#linux           :centos7
#user            :root
#config file     :install.properties
#comment         :1.15.x1.16.6
#==============================================================================
set -e
current_dir=$(cd "$(dirname "$0")";pwd)
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

./backup.sh

#
./generate_conf.sh

#
log INFO "decompressing install package"
rm -rf dockin-package;
tar zxvf ../resources/dockin-package.tar.gz;

# proxy
for i in $(ls ./dockin-package/package/*.tar); do echo "loading $i"; docker load --input $i; done


kube_version="v1.16.6"
binary_dir="dockin-package/binary"
if [[ $(kubeadm version | grep ${kube_version}) == "" ]]; then
    cp -f ${binary_dir}/kubeadm /usr/bin/
fi

if [[ $(kubectl version | grep "Client Version" | grep ${kube_version}) == "" ]]; then
    cp -f ${binary_dir}/kubectl /usr/bin/
fi

if [[ $(kubelet --version | cut -d ' ' -f 2) != ${kube_version} ]]; then
      cp -f ${binary_dir}/kubelet /usr/bin/
fi

sed -i 's/\/etc\/sysconfig\/kubelet/\/data\/kubernetes\/config\/kubelet-extra-args/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf;
echo "1" >/proc/sys/net/bridge/bridge-nf-call-iptables

kubeadm upgrade plan ${kube_version} --config tmp/master-config/kubeadm-config.yaml --ignore-preflight-errors=CoreDNSUnsupportedPlugins
# master
kubeadm upgrade apply ${kube_version} --config tmp/master-config/kubeadm-config.yaml --ignore-preflight-errors=CoreDNSUnsupportedPlugins --certificate-renewal=false --force --yes --v=4


kubeadm upgrade node config --kubelet-version $(kubelet --version | cut -d ' ' -f 2)

kubeadm alpha certs check-expiration --config=tmp/master-config/kubeadm-config.yaml

systemctl daemon-reload
systemctl restart kubelet

sleep 20;

# flannel
flannel_yaml=${current_dir}/../../../common/flannel-cni/kube-flannel.yaml
[ -f ../resources/flannel-cni/kube-flannel.yaml ] && flannel_yaml=${current_dir}/../resources/flannel-cni/kube-flannel.yaml

kubectl delete -f ${flannel_yaml}
kubectl apply -f ${flannel_yaml}

# core dns
core_dns_yaml=${current_dir}/../../../common/addons/core-dns/core-dns-deployment.yaml
[ -f ../resources/addons/core-dns/core-dns-deployment.yaml ] && core_dns_yaml=${current_dir}/../resources/addons/core-dns/core-dns-deployment.yaml

kubectl apply -f ${core_dns_yaml}

#
if [[ "$(kubectl get nodes | grep ${kube_version})" == "" ]]; then
    log ERROR "kubernetes upgrade to ${kube_version} failed";
#    exit 1;
fi

$current_dir/renew_certs.sh

rm -rf dockin-package tmp
