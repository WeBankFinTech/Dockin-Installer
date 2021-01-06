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
#description     :install or upgrade kubernetes cluster
#author
#linux           :centos7
#user            :root
#config file     :install.properties
#comment         :
#==============================================================================
set -e

current_dir=$(cd "$(dirname "$0")";pwd)
declare -A map_version
map_version=(["v1.12.5"]=12 ["v1.13.12"]=13 ["v1.14.10"]=14 ["v1.15.7"]=15 ["v1.16.6"]=16)
upgrade_version_list=("v1.12.5" "v1.13.12" "v1.14.10" "v1.15.7" "v1.16.6")
install_version_list=("v1.12.5" "v1.16.6")
upgrade_additional_version_list=("v1.16.6")

function log() {
    level=$1
    message=$2
    log="`date +'%Y-%m-%d %H:%M:%S'`,$LINENO [$level] - $message"
    echo $log
}

function usage(){
    echo "init a cluster"
    echo "usage: ./install install version first_node=(true/false)"
    echo "if this master is first node, please input first_node=true, else first_node=false"
    echo "current support version list: v1.16.6"
    echo ""
    echo ""
    echo "upgrade a cluster version"
    echo "usage: ./install upgrade  version"
    echo "current support version list: v1.13.12 v1.14.10 v1.15.7 v1.16.6"
    echo ""
    echo ""
    echo "upgrade a cluster additional master version"
    echo "usage: ./install upgrade_additional  version"
    echo "current support version list: v1.16.6"
}

if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

function get_current_version(){
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
	install_version=$1
	first_node=$2
	install_version_support ${install_version}
	
	cd $current_dir/version/${install_version}/install
    chmod +x *.sh
    ./install.sh ${first_node}
    echo "install to version:$ver succ"
    echo "start to install kubernetes"
}

function install_version_support(){
	install_version=$1

    if [[ ${install_version_list[@]/${install_version}/} == ${install_version_list[@]} ]];then
        echo "not support k8s install to version:$install_version"
        exit 1
    fi
	return 0
}

function upgrade_additional_version_support(){
	install_version=$1

	 if [[ ${upgrade_additional_version_list[@]/${install_version}/} == ${upgrade_additional_version_list[@]} ]];then
        echo "not support k8s install to version:$install_version"
        exit 1
    fi
	return 0
}

function upgrade_version_support(){
    current_version=$1
    upgrade_version=$2
    if [[ ${upgrade_version_list[@]/${current_version}/} == ${upgrade_version_list[@]} ]];then
        echo "not support current k8s version:$current_version upgrade"
        exit 0
    fi

    if [[ ${upgrade_version_list[@]/${upgrade_version}/} == ${upgrade_version_list[@]} ]];then
        echo "not support k8s upgrade to version:$upgrade_version"
        exit 0

    fi

    if [ $current_version == $upgrade_version ];then
        echo "no need to upgrade,current version:$current_version,upgrade version:$upgrade_version"
        exit 0
    fi
    return 0

}

function upgrade(){
    current_version=$(get_current_version)
    upgrade_version=$1
    upgrade_version_support $current_version $upgrade_version

    for ver in ${upgrade_version_list[@]}
    do
        if [ ${map_version[$current_version]} -lt ${map_version[$ver]} -a ${map_version[$upgrade_version]} -ge ${map_version[$ver]} ];then
            cd $current_dir/version/$ver/upgrade
            chmod +x *.sh
            ./upgrade.sh
            echo "upgrade to version:$ver succ"
        fi
    done
    echo "end to upgrade kubernetes"
}

function upgrade_additional(){
    upgrade_version=$1
    upgrade_additional_version_support $upgrade_version

    cd $current_dir/version/${upgrade_version}/upgrade
    chmod +x *.sh
    ./upgrade_additional.sh
    echo "upgrade additional master to version:$ver succ"
}

type=$1
version=$2
if [ $type == "install" ];then
    install $version $3
elif [ $type == "upgrade" ];then
    upgrade $version
elif [ $type == "upgrade_additional" ];then
    upgrade_additional $version
else
    usage
fi