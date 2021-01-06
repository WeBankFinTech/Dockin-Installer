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

date

if [[ $(grep "$1" /etc/docker/daemon.json) != "" ]]; then
    echo "this host registry already updated"
else
    sed -i "/$1/d" /etc/docker/daemon.json; sed -i "/registry-mirrors/a  \"http://$1\"," /etc/docker/daemon.json
    sed -i "/uat.sf.dockerhub.stgwebank/d" /etc/docker/daemon.json; sed -i "/$1/a  \"https://uat.sf.dockerhub.stgwebank\"," /etc/docker/daemon.json
    sed -i "/mirror.ccs.tencentyun.com/d" /etc/docker/daemon.json; sed -i "/uat.sf.dockerhub.stgwebank/a  \"https://mirror.ccs.tencentyun.com\"" /etc/docker/daemon.json
    systemctl daemon-reload
    systemctl restart dockerd
    systemctl restart docker
    echo "update success";
fi


