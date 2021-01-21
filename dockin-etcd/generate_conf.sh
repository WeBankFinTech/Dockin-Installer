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
#description     :etcd conf.yaml generator
#author		     :lihuan
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

function validate_local_ip(){
    for ip in $(ifconfig | grep "inet " | awk -F ' ' {'print $2'} ); do
        if [[ $(echo $ip | grep "addr:") != "" ]]; then
                ip=$(echo $ip | awk -F ':' {'print $2'})
        fi
        for item in ${server_list[@]}; do
            if [[ "${item}" = "${ip}" ]]; then
                export local_ip=${item}
                return 0;
            fi
        done
    done
    log ERROR "local ip are NOT in server_list."
    exit 1
}

#generate initial-cluster-urls
function gen_urls(){
    for item in ${server_list[@]}; do
        if [[ -z "${initial_cluster}" ]] ; then
            initial_cluster="etcd-$item=https://${item}:5380"
        else
            initial_cluster=${initial_cluster}",etcd-$item=https://${item}:5380"
        fi
    done
    export initial_cluster=${initial_cluster}
}

#generate ssl-server-list for
function gen_ssl_server_list(){
    ssl_server_list="\"127.0.0.1\""
    for item in ${server_list[@]}; do
        ssl_server_list=${ssl_server_list}",\"$item\""
    done
    export ssl_server_list=${ssl_server_list}
}

#==============================================================================
# scripts starts here.

if [ $# -ne 1 ]; then
	echo "$0 [data_path]"
	exit 1
fi

data_path=$1
APP_NAME=$(head -n1 .name)
. ${SCRIPT_PATH}/$APP_NAME/conf/install.properties

validate_local_ip && echo "local ip address=[$local_ip]."

gen_urls && echo "initial-cluster-urls=[${initial_cluster}]."
gen_ssl_server_list && echo "etcd ssl server list =[$ssl_server_list]."

#write conf.yaml
cd  $SCRIPT_PATH/$APP_NAME/conf/
cp template.conf.yaml conf.yaml;
sed -i "s#current-ip-address#${local_ip}#g" conf.yaml
sed -i "s#initial-cluster-urls#${initial_cluster}#g" conf.yaml
sed -i "s#data-dir: .*#data-dir: ${data_path}#g" conf.yaml
sed -i "s#ssl_server_list#${ssl_server_list}#g" $SCRIPT_PATH/$APP_NAME/tools/ca-gen/server.json
chmod +x $SCRIPT_PATH/$APP_NAME/tools/ca-gen/*
cd $SCRIPT_PATH/$APP_NAME/tools/ca-gen/
sh $SCRIPT_PATH/$APP_NAME/tools/ca-gen/gen-ca.sh
cp $SCRIPT_PATH/$APP_NAME/tools/ca-gen/*.pem $SCRIPT_PATH/$APP_NAME/conf/
log INFO "generate successfully ..."

exit 0;
