#!/bin/sh

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
#description     :install docker v19.03, with runc build flag nokmem
#author		     :
#docker version: :v19.03
#linux           :centos7
#user            :root
#Get docker-ce binary from: https://download.docker.com/linux/static/stable/x86_64/
#==============================================================================
set -ex

SYSTEM_DIR=/usr/lib/systemd/system
SERVICE_FILE=docker.service
SERVICE_NAME=docker
DOCKER_BIN_DIR=/usr/bin
BIN_PACKAGE=package
FILE_TARGZ=package/docker-19.03.12.tgz

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "running preflight checks ..."
[[ "$USER" != "root" ]] && { echo "ERROR current user is not root."; exit 1; }

echo "unzip : tar xvpf ${FILE_TARGZ}"
tar xvpf ${FILE_TARGZ} -C ${BIN_PACKAGE}/
echo ""

echo "remove 18 dockerd symlink"
rm -rf /usr/bin/dockerd

echo "remove /var/lib/docker"
rm -rf /var/lib/docker;
echo "init working directory [/data/docker]."
mkdir -pv /data/docker
ln -sv /data/docker /var/lib/docker

echo "install docker 19.03..."
echo "binary : ${BIN_PACKAGE}/docker copy to ${DOCKER_BIN_DIR}"
cp -f ${BIN_PACKAGE}/docker/* ${DOCKER_BIN_DIR}

# replace runc with nokem version
echo "replace runc with nokem version"
chmod u+x ${BIN_PACKAGE}/runc
cp ${BIN_PACKAGE}/runc /usr/bin -f

echo "add docker daemon config."
rm -rf /etc/docker/daemon.json
mkdir -p /etc/docker
cp -r daemon.json /etc/docker/

echo "systemd service: ${SERVICE_FILE}"
echo "docker.service: create docker systemd file"

cat >${SYSTEM_DIR}/${SERVICE_FILE} <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target docker.socket
[Service]
Type=notify
EnvironmentFile=-/run/flannel/docker
WorkingDirectory=/usr/local/bin
ExecStart=/usr/bin/dockerd \
                -H unix:///var/run/docker.sock \
                --selinux-enabled=false
ExecReload=/bin/kill -s HUP $MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

echo ""

systemctl daemon-reload
echo "Service restart: ${SERVICE_NAME}"
systemctl restart ${SERVICE_NAME}
echo "Service status: ${SERVICE_NAME}"
systemctl status ${SERVICE_NAME}

echo "Service enabled: ${SERVICE_NAME}"
systemctl enable ${SERVICE_NAME}


docker_process=$(ps -ef | grep "dockerd" | grep -v "grep") || true
if [[ $docker_process == "" ]]; then
    echo "docker start failed, please check"
    exit 1
else
    pid=$(echo $docker_process| awk -F ' ' {'print $2'})
    if [[ $pid == "" ]]; then
        echo "docker start failed, please check"
        exit 1
    else
        echo "docker start success, pid=$pid"
    fi
fi

echo "docker info"
docker info

echo "docker version"
docker version

