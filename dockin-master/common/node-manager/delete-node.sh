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
#description     :remove a node from kubernetes cluster.
#author		       :
#linux           :centos7
#user            :root
#comment         :Node（ETCD）。Node。
#==============================================================================

# root
if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

function usage(){
    echo "delete-node.sh nodeName";
}

function delete_node(){
  echo $1;
  kubectl drain $1 --delete-local-data --force --ignore-daemonsets
  kubectl delete node $1
}


if [ $# == 1 ]; then
    delete_node $1
else
    usage
fi


