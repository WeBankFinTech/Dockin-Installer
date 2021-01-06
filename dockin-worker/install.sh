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
#description     :install or upgrade kubernetes cluster agent
#author
#linux           :centos7
#user            :root
#config file     :install.properties
#comment         :
#==============================================================================
set -ex

current_dir=$(cd "$(dirname "$0")";pwd)
list_version=("v1.12.5" "v1.13.12" "v1.14.10" "v1.15.7" "v1.16.6")

function log() {
    level=$1
    message=$2
    log="`date +'%Y-%m-%d %H:%M:%S'`,$LINENO [$level] - $message"
    echo $log
}

function usage(){
    echo "usa install like:"
    echo "./install install version master_node=true/false";
    echo "./install upgrade version"
    exit 1;
}

# root
if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

function get_current_version(){
    # kubectl
    if [ ! -f "/bin/kubectl" ]; then
      log ERROR "kubectl is NOT installed, please exec agent install first";
      exit 1;
    fi

    str=$(kubectl version | grep "Server Version")
    version=${str#*GitVersion:\"}
    echo ${version%%\"*}

    return 0
}

if [ $# -lt 2 ];then
    usage
    exit
fi


function install(){
    echo "start to install kubernetes"

    install_version=$1
    master_node=$2
	version_support ${install_version}
	cd $current_dir/version/${install_version}/install
    chmod +x *.sh
    ./install.sh

    echo "install to version:$ver success"

    if [[ $master_node == "false" ]]; then
        # join to cluster
        ./node-join-cluster.sh
        echo "join to cluster success"
    fi
}

function version_support(){
    upgrade_version=$1

    if [[ ${list_version[@]/${upgrade_version}/} == ${list_version[@]} ]];then
        echo "not support k8s version:$upgrade_version"
        exit 0

    fi

    return 0

}

function upgrade(){
    upgrade_version=$1
    version_support $upgrade_version

    cd $current_dir/version/${upgrade_version}/upgrade
    chmod +x *.sh
    ./upgrade.sh
    echo "upgrade to version:$version success"

    echo "end to upgrade kubernetes"
}


type=$1
version=$2

export $3
if [ -z "$master_node" ]; then
    echo "You must specify master_node"
    usage
fi
if [[ $master_node == "" ]]; then
    echo "You must specify master_node"
  usage
fi

if [ $type == "install" ];then
    install $version $master_node
elif [ $type == "upgrade" ];then
    upgrade $version
else
    usage
fi