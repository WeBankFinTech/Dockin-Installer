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
#description     :uninstall docker v17.03.
#author		     :
#kubernetes version: v1.11.2
#docker version: :v17.03
#linux           :centos7
#user            :root
# add by , modify docker uninstall, add 18.08 containerd
#==============================================================================
set -x
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "running preflight checks ..."
[[ "$USER" != "root" ]] && { echo "ERROR current user is not root."; exit 1; }

# shutdown kubelet when exist
if [ -f "/usr/bin/kubelet" ]; then
    echo "stop kubelet."
    systemctl stop kubelet
fi

# close live restore and reload
sed -i "/live-restore/d" /etc/docker/daemon.json
sed -i "/insecure-registries/i \"live-restore\":false," /etc/docker/daemon.json
#kill -SIGHUP $(pidof dockerd)
systemctl restart docker

echo "disable docker service and stop it."
systemctl disable docker && systemctl stop docker;
systemctl stop containerd && systemctl disable containerd;


if [ $(rpm -qa|grep docker|wc -l) != 0 ]; then
    rpm -qa|grep docker|xargs yum remove -y
fi

echo "uninstall containerd..."
if [ $(rpm -qa|grep container|wc -l) != 0 ]; then
    rpm -qa|grep container|xargs yum remove -y
fi

echo "clean up working directory [/data/docker]."
rm -rf /data/docker;
rm -rf /var/lib/docker;
echo "remove 18 dockerd symlink"
rm -rf /usr/bin/dockerd

echo "check dockerd process status ..."
docker_process=$(ps -ef | grep "dockerd" | grep -v "grep") || true
if [[ $docker_process == "" ]]; then
    echo "dockerd process not found."
else
    pid=$(echo ${docker_process}| awk -F ' ' {'print $2'})
    echo "dockerd is still RUNNING, pid=$pid."
    echo "uninstall docker failed!!"
    exit 2
fi

exit 0;
