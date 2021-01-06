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
#description     :dockin-etcd build script.
#author		       :
#==============================================================================
set -e
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#==============================================================================
#functions
function log() {
    level=$1
    message=$2
    log="`date +'%Y-%m-%d %H:%M:%S'`,$LINENO [$level] - $message"
    echo $log
}

function usage(){
    echo "build.sh usage examples:";
    echo "build.sh";
    echo "build.sh clean";
    echo "build.sh package";
}

function clean(){
    cd ${SCRIPT_PATH};
    rm -rf build/;
    rm -rf dist/;
}

function copy_files(){
    cd ${SCRIPT_PATH};
    mkdir build;
    mkdir -p ./build/$name
    mkdir -p ./dist
    echo "$name" > ./build/.name
    cp generate_conf.sh install.sh build/;
    cp -R bin conf tools build/$name;
}

function package(){
    clean
    copy_files
    cd ${SCRIPT_PATH}/build
    tar -czf ${SCRIPT_PATH}/build/$name\_$version\_$1.tar.gz * .name
    cp ${SCRIPT_PATH}/build/$name\_$version\_$1.tar.gz ${SCRIPT_PATH}/dist/
}

function all_in_one(){
    clean && package
}
# =============================================================================
# script starts here.
cd ${SCRIPT_PATH};
. build.properties
# parse command line.
OPTS=`getopt -o h:: --long help::  -- "$@"`
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
    "")         all_in_one;     exit $?;;
    *)          log ERROR "unkown task name[${task}]." ; usage; exit 1;;
esac
