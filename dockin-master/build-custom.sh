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

set -e
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

declare -A map_version
map_version=(["v1.12.5"]=12 ["v1.13.12"]=13 ["v1.14.10"]=14 ["v1.15.7"]=15 ["v1.16.6"]=16)
list_version=("v1.12.5" "v1.13.12" "v1.14.10" "v1.15.7" "v1.16.6")
#==============================================================================
#functions
function log() {
    level=$1
    message=$2
    log="`date +'%Y-%m-%d %H:%M:%S'`,$LINENO [$level] - $message"
    echo $log
}

function usage(){
    package_usage;
}

function clean(){
    rm -rf build/;
    rm -rf dist/;
}

function copy_files(){ exit 0; }

function install_support(){
    install_version=$1
    if [[ ${list_version[@]/${install_version}/} == ${list_version[@]} ]];then
        echo "not support k8s install to version:$install_version package"
        exit 0

    fi

}

function upgrade_support(){
    current_version=$1
    upgrade_version=$2

     if [[ ${list_version[@]/${current_version}/} == ${list_version[@]} ]];then
            echo "not support current k8s version:$current_version upgrade package"
            exit 0
        fi

        if [[ ${list_version[@]/${upgrade_version}/} == ${list_version[@]} ]];then
            echo "not support k8s upgrade to version:$upgrade_version package"
            exit 0

        fi

        if [ $current_version == $upgrade_version ];then
            echo "no need to upgrade,current version:$current_version,upgrade version:$upgrade_version"
            exit 0
        fi
        return 0
}

function package_usage(){
    echo "usa package like:"
    echo "./build.sh package buildnum install version"
    echo "./build.sh package buildnum upgrade currrent_version upgrade_version"
    echo "version list: v1.12.5 v1.13.12 v1.14.10 v1.15.7 v1.16.6"
    exit 1
}

function update_file_code(){
    chmod -R +x *.sh
    #find . -name "*.sh" -print0 | xargs -0 dos2unix
    #find . -name "*.properties" -print0 | xargs -0 dos2unix
}

function package_install(){
	k8s_version=$2
	install_support $k8s_version
    update_file_code
    tar_name="${SCRIPT_PATH}/dist/${name}_${version}_$1.tar.gz"
	
	tar -zcvf ${tar_name} *.sh conf common version/$k8s_version
}

function package_upgrade(){
    current_version=$2
    upgrade_version=$3
    upgrade_support $current_version $upgrade_version

    update_file_code
	tar_name="${SCRIPT_PATH}/dist/${name}_${current_version}-${upgrade_version}_$1.tar.gz"
    tar_cmd="tar -zcvf ${tar_name} common conf *.sh "

    for ver in ${list_version[@]}
    do
        if [ ${map_version[$current_version]} -lt ${map_version[$ver]} -a ${map_version[$upgrade_version]} -ge ${map_version[$ver]} ];then
            tar_cmd=$tar_cmd"version/$ver "
        fi
    done

    tar_cmd=$tar_cmd"install.sh "


    ${tar_cmd}
}

function package(){
    if [ $# -lt 3 ];then
        package_usage
    fi
    buildNum=$1
    type=$2

	clean
    mkdir -p $SCRIPT_PATH/dist/

    if [ "install" == $type ];then
        k8s_version=$3
        package_install ${buildNum} $k8s_version
    elif [ "upgrade" == $type ];then
         if [ $# -lt 4 ];then
            package_usage
         fi

        current_version=$3
        upgrade_version=$4

        package_upgrade ${buildNum} $current_version $upgrade_version
    else
        package_usage
    fi

}

function upload(){
    cd ${SCRIPT_PATH}
    ./upload.sh -t ./dist/$name"_"$version"_""$1".tar.gz -u $subsystem
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
    "upload")   upload $2;     exit $?;;
    *)          log ERROR "unkown task name[${task}]." ; usage; exit 1;;
esac
