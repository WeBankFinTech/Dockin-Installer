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

###################################
# etcd install script
###################################
set -e
function log() {
    level=$1
    message=$2
    log="`date +'%Y-%m-%d %H:%M:%S'`,$LINENO [$level] - $message"
    echo $log
}
# =============================================================================
# script starts here.
#install.sh 自身在的目录
SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd ${SCRIPT_PATH};

# parse command line.
OPTS=`getopt -o c:p:d:f:b: --long config:,data-path,path:,file:,backup:,docker::,update-config::,update-config-only::  -- "$@"`
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi
eval set -- "$OPTS"
#log DEBUG "$@"
while true ; do
        case "$1" in
                -p|--path) OPT_PATH="$2"; shift 2;;
                -c|--config) OPT_CONF="$2"; shift 2;;
                -b|--backup) OPT_BACKUP=$2; shift 2;;
                -d|--data-path) OPT_DATA_PATH="$2"; shift 2;;
                --update-config) OPT_UPDATE_CONFIG=true; shift 2;;
                --update-config-only) OPT_UPDATE_CONFIG=true; OPT_UPDATE_CONFIG_ONLY=true; shift 2;;
                --) shift ; break ;;
                *) echo "parse command line error: [$1]." ; exit 1 ;;
        esac
done

#安装数据文件主目录
CONTENT_PATH="$SCRIPT_PATH/$(head -n1 .name)"
CONTENT_NAME=$(head -n1 .name)
[ -d "$CONTENT_PATH" ] || { log CRITICAL "$CONTENT_PATH/ does NOT exist or is NOT a directory."; exit 9; }

# 本次安装的是不是备份服务器，备份服务器在安装结束时不会执行start.sh，但是在安装的过程中stop.sh�?定会执行�?次�??
IS_BACKUP_SERVER=$OPT_BACKUP
if [ -z "$IS_BACKUP_SERVER" ];then
	[[ "$M_START_SERVER" == true ]] && IS_BACKUP_SERVER=false
	[[ "$M_START_SERVER" == false ]] && IS_BACKUP_SERVER=true
fi
[ -z "$IS_BACKUP_SERVER" ] && IS_BACKUP_SERVER=false
[[ "$IS_BACKUP_SERVER" != false && "$IS_BACKUP_SERVER" != true ]] && { log ERRROR "value is invalid [$IS_BACKUP_SERVER]."; exit 33; }

# decide install settings(command line options > M_* env variables > install.conf ).
# 安装目标目录
DEPLOY_PATH=${OPT_PATH}
[ -z "$DEPLOY_PATH" ] && DEPLOY_PATH="/data/app/$CONTENT_NAME"
APP_NAME=$(basename "$DEPLOY_PATH")
DATA_PATH="/data/$APP_NAME/data"
#如果指定data目录，则替换data目录
if [ ! "$OPT_DATA_PATH" = "" ]; then
    DATA_PATH=$OPT_DATA_PATH
fi
LOG_PATH="/data/$APP_NAME/logs"
log INFO "APP_NAME=$APP_NAME"
log INFO "DEPLOY_PATH=$DEPLOY_PATH"
log INFO "LOG_PATH=$LOG_PATH"
log INFO "DATA_PATH=$DATA_PATH"
#配置
#OPT_CONF > M_CONF_NAME > CONF_NAME
CONFIGS=$OPT_CONF
[ -z "$CONFIGS" ] && CONFIGS=$M_CONF_NAME
[ -z "$CONFIGS" ] && CONFIGS=$CONF_NAME

# 根据配置修改安装配置目录
if [ -z "$CONFIGS" ]; then
	log INFO "CONFIGS=[$CONFIGS], using default configuration."
else
	log INFO "CONFIGS=[$CONFIGS], using configuration in $CONTENT_PATH/env/$CONFIGS."
fi

#generate conf file
log INFO "generate config file by using data configuration $DATA_PATH."
./generate_conf.sh $CONFIGS $DATA_PATH

if [ -n "$CONFIGS" ]; then
	cd "$CONTENT_PATH"
	[ -d "env/$CONFIGS/" ] || { log ERROR "origin conf not found,$CONFIGS.";exit 1; }
	for file in $(ls "env/$CONFIGS/" | grep -v ".sh"); do
		cp -vrf "env/$CONFIGS/$file" conf
	done
fi

# 初始化日志目录和服务器目录
if [ ! -e "$LOG_PATH" ]; then
    log INFO "create log path: $APP_NAME."
    mkdir -vp "$LOG_PATH"
fi

if [ ! -e "$DATA_PATH" ]; then
    log INFO "create data path: $DATA_PATH."
    mkdir -vp "$DATA_PATH"
fi

if [ ! -e "$DEPLOY_PATH" ]; then
    mkdir -vp "$DEPLOY_PATH"
fi


BWLIMIT=1000

#更新服务器配置目录
if [[ "$OPT_UPDATE_CONFIG" ]]; then
    log INFO "update config ..."
    cd ${SCRIPT_PATH}
    if [[ "$OPT_UPDATE_CONFIG_ONLY" ]]; then
        log INFO "md5sum check ..."
        list=$(rsync -n -cir --delete "$CONTENT_PATH/" "$DEPLOY_PATH/" --exclude=/logs --exclude=/data --exclude=/tmp --exclude=tomcat --exclude="/.*" --exclude="/bin" | awk '{print $2}'| grep -Ev "^(conf|env)"||true)
        if [[ -n "$list" ]]; then
            log ERROR "md5sum check failed:"
            rsync -n -cir --delete "$CONTENT_PATH/" "$DEPLOY_PATH/" --exclude=/logs --exclude=/data --exclude=/tmp --exclude=tomcat --exclude="/.*" --exclude="/bin" | awk '{print $2}'| grep -Ev "^(conf|env)"
            log WARN "update-config-only task abort, file in $DEPLOY_PATH is UNTOUCHED."
            exit 3;
        fi
    fi

    rsync -cir --delete --bwlimit=$BWLIMIT "$CONTENT_PATH/" "$DEPLOY_PATH/" --exclude=/logs --exclude=/data --exclude=/tmp --exclude=tomcat --exclude="/.*" --exclude="/bin";
    log INFO "update config success."
    exit 0;
fi

# 关闭服务
if [[ true != "$OPT_UPDATE_CONFIG_ONLY" && -r $DEPLOY_PATH/bin/stop.sh ]]; then
    log WARN "old installation found, try to stop old process, if it exists."
    cd $DEPLOY_PATH/bin
	sh stop.sh
fi

# 安装服务
cd ${SCRIPT_PATH}
rsync -cir --delete --bwlimit=$BWLIMIT "$CONTENT_PATH/" "$DEPLOY_PATH/" --exclude=/logs --exclude=/data  --exclude=/tmp --exclude=tomcat --exclude="/.*";

if [ ! -d "$DEPLOY_PATH/logs" ]; then
    ln -sf "$LOG_PATH" "$DEPLOY_PATH/logs"
    log INFO "ln logs..."
fi

if [ ! -d "$DEPLOY_PATH/data" ]; then
    ln -sf "$DATA_PATH" "$DEPLOY_PATH/data"
    log INFO "ln data..."
fi

chmod 775 ${DEPLOY_PATH}/bin/*

#将二进制文件写到环境变量中
BIN_PATH=$DEPLOY_PATH/bin
if [[ $(cat ~/.bashrc | grep "alias" | grep "etcdctl=$BIN_PATH/etcdctl" ) == "" ]]; then
    echo 'export ETCDCTL_API=3' >> ~/.bashrc
    echo 'alias etcdctl='"$BIN_PATH/etcdctl" >> ~/.bashrc
    source ~/.bashrc
    log INFO "add bin alias to bashrc successfully ..."
fi

[[ -d "$DEPLOY_PATH/scripts" ]] && chmod -R +x ${DEPLOY_PATH}/scripts/ || true

#启动服务
if [[ "$IS_BACKUP_SERVER" == false ]]; then
	log INFO "starting server..."
	cd $DEPLOY_PATH/bin
	sh start.sh
fi

