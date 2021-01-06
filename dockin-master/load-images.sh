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
#description     :load all images
#author
#linux           :centos7
#user            :root
#config file     :install.properties
#comment         :
#==============================================================================
set -x

current_dir=$(cd "$(dirname "$0")";pwd)
declare -A map_version
map_version=(["v1.12.5"]=12 ["v1.13.12"]=13 ["v1.14.10"]=14 ["v1.15.7"]=15 ["v1.16.6"]=16)
list_version=("v1.12.5" "v1.13.12" "v1.14.10" "v1.15.7" "v1.16.6")
install_version_list=("v1.12.5" "v1.16.6")

function log() {
    level=$1
    message=$2
    log="`date +'%Y-%m-%d %H:%M:%S'`,$LINENO [$level] - $message"
    echo $log
}

for ver in ${list_version[@]}
do
    cd $current_dir/version/$ver/resources

    tar zxvf ../resources/dockin-package.tar.gz;
    if [ ${map_version[$ver]} -ge 16 ];then
        for i in $(ls ./dockin-package/package/*.tar); do echo "loading $i"; docker load --input $i; done
    else
        for i in $(ls ./package/*.tar); do echo "loading $i"; docker load --input $i; done
    fi
    log INFO "load images kubernetes version:$ver succ"

    rm -rf dockin-package package binary;

done


