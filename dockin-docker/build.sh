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
#author		     :
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
    echo "build.sh build_number";
    echo "build.sh clean build_number";
    echo "build.sh package build_number";
    echo "build.sh upload build_number";
}

function clean(){
    rm -rf build/;
    rm -rf dist/;
}

function copy_files(){ exit 0; }

function package(){
    clean
    mkdir -p $SCRIPT_PATH/dist/
    cd resources
    chmod -R +x *.sh
    tar -czvf ${SCRIPT_PATH}/dist/$name"_"$version"_""$1".tar.gz *
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
    "package")  package $2;    exit $? ;;
    "upload")   upload $2;     exit $?;;
    *)          log ERROR "unkown task name[${task}]." ; usage; exit 1;;
esac
