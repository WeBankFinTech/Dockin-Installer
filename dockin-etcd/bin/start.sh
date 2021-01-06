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
# start etcd server
################################

#
function add_crontab(){
	crontab -l | grep -v "$APP_HOME/scripts/backup.sh" | grep -v "$APP_HOME/scripts/monitor.sh"  > tmp_crontab.txt || true
	echo "5 * * * * sh $APP_HOME/scripts/backup.sh  >> $APP_HOME/logs/backup.log 2>&1" >> tmp_crontab.txt
	echo "* * * * * sh $APP_HOME/scripts/monitor.sh  >> $APP_HOME/logs/dockin-etcd.log 2>&1" >> tmp_crontab.txt
	crontab tmp_crontab.txt
	rm -f tmp_crontab.txt
}

#script starts here
set -e
APP_BIN="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_HOME="$(dirname $APP_BIN)"; [ -d "$APP_HOME" ] || { echo "ERROR dockin-etcd failed to detect APP_HOME."; exit 1;}
APP_NAME=$(basename "$APP_HOME")

cmd="$APP_HOME/bin/etcd --config-file=$APP_HOME/conf/conf.yaml"
log_path="$APP_HOME/logs/$APP_NAME.log"
python $APP_HOME/bin/run.py -c "$cmd" -l "$log_path" &

start_timeout=30
for no in $(seq 1 $start_timeout); do
    pid=$(sh $APP_HOME/bin/ps.sh| awk -F ' ' {'print $2'})
    if [ "$pid" = "" ]; then
        if [ $no -lt $start_timeout ]; then
            echo "[$no] starting server ..."
            sleep 1
            continue
        fi
        echo "start server timeout"; break;
    else
        echo -e "etcd server start success, pid=$pid"; add_crontab; break;
    fi
done





