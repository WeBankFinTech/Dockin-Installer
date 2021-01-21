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
#name            :dockin node init v1.0.
#description     :。：node
#author		       :
#linux           :centos7
#user            :root
#==============================================================================
set -e

# root
if [ $UID -ne 0 ]; then
    echo "Superuser privileges are required to run this script."
    echo "e.g. \"sudo $0\""
    exit 1
fi

function usage(){
    echo "dockin-node-init.sh node-name";
}

function node_init(){
    kubectl label nodes $1 node-role.kubernetes.io/dockin=true
}

if [ $# == 1 ]; then
    node_init $1
else
    usage
fi