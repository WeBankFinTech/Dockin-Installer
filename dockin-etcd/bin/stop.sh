#!/bin/bash
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

################################
# stop etcd server
################################
set -e
APP_BIN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_HOME="$(dirname $APP_BIN)"; [ -d "$APP_HOME" ] || { echo "ERROR dockin-etcd failed to detect APP_HOME."; exit 1;}
APP_NAME=$(basename "$APP_HOME")

pid=$(sh $APP_HOME/bin/ps.sh| awk -F ' ' {'print $2'})
if [ "$pid" = "" ]; then
    echo -e "etcd server not start"
    exit 0;
fi
kill -15 $pid;
[[ $OS =~ Msys ]] && PS_PARAM=" -W "
stop_timeout=30
for no in $(seq 1 $stop_timeout); do
    if ps $PS_PARAM -p "$pid" 2>&1 > /dev/null; then
        if [ $no -lt $stop_timeout ]; then
            echo "[$no] shutdown server ..."
            sleep 1
            continue
        fi
        echo "shutdown server timeout, kill process: $pid"
        kill -9 $pid; sleep 1; break;
    else
        echo "shutdown server ok!"; break;
    fi
done





