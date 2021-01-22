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
#description     :dockin-agent build script.
#author		     :
#==============================================================================
set -e
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#==============================================================================
declare -A map_version
map_version=(["v1.12.5"]=12 ["v1.13.12"]=13 ["v1.14.10"]=14 ["v1.15.7"]=15 ["v1.16.6"]=16)
list_version=("v1.12.5" "v1.13.12" "v1.14.10" "v1.15.7" "v1.16.6")

#functions
function log() {
    level=$1
    message=$2
    log="`date +'%Y-%m-%d %H:%M:%S'`,$LINENO [$level] - $message"
    echo $log
}

function usage(){
    echo "build.sh usage examples:";
    echo "build.sh build_number";
    echo "build.sh clean build_number";
    echo "build.sh package build_number";
    echo "build.sh upload build_number";
}

function package_usage(){
    echo "usa package like:"
    echo "./build.sh package buildnum install version"
    echo "version list: v1.12.5 v1.13.12 v1.14.10 v1.15.7 v1.16.6"
    exit 1
}

function clean(){
    rm -rf build/;
    rm -rf dist/;
}

function update_file_code(){
    chmod -R +x *.sh
    #find . -name "*.sh" -print0 | xargs -0 dos2unix
    #find . -name "*.properties" -print0 | xargs -0 dos2unix
}

function copy_files(){ exit 0; }

function install_support(){
    install_version=$1

    if [[ ${list_version[@]/${install_version}/} == ${list_version[@]} ]];then
        echo "not support k8s install to version:$install_version package"
        exit 0
    fi

        return 0
}


function upgrade_support(){
    upgrade_version=$1

    if [[ ${list_version[@]/${upgrade_version}/} == ${list_version[@]} ]];then
        echo "not support k8s upgrade to version:$upgrade_version package"
        exit 0

    fi

        return 0
}

function package_install(){
	k8s_version=$2
	upgrade_support ${k8s_version}
	update_file_code
	tar_name="${SCRIPT_PATH}/dist/${name}_${version}_$1.tar.gz"
	
	tar -zcvf ${tar_name} cni common conf install.sh uninstall.sh  version/$k8s_version
}

function package_upgrade(){
	echo "nothing to do "
	exit 1
}

function package(){
    if [ $# -lt 3 ];then
            package_usage
    fi
    buildNum=$1
    type=$2
    k8s_version=$3
    clean
    mkdir -p $SCRIPT_PATH/dist/
    chmod -R +x *.sh

     package_install ${buildNum} $k8s_version
}

function upload(){
    cd ${SCRIPT_PATH}
     buildNum=$1
    type=$2
    k8s_version=$3
	tar_name="${name}_${version}_${k8s_version}B$buildNum.tar.gz"

    echo $tar_name
    ./upload.sh -t ./dist/$tar_name -u $subsystem
}

function all_in_one(){
    clean && package $1
}
# =============================================================================
# script starts here.
cd ${SCRIPT_PATH};
. build.properties
# parse command line.
OPTS=`getopt -o h: --long help::  -- "$@"`
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$OPTS"
#log DEBUG "$@"
while true ; do
        case "$1" in
                -h|--help) usage;exit 0; shift 2;;
                --) shift ; break ;;
                *) echo "parse command line error: [$1]." ; exit 1 ;;
        esac
done

task=$1
case ${task} in
    "clean")    clean;      exit $?;;
    "package")  package ${@:2};    exit $? ;;
    "upload")   upload ${@:2};     exit $?;;
    *)          log ERROR "unkown task name[${task}]." ; usage; exit 1;;
esac
