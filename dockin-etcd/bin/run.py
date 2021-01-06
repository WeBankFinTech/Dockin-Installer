#!/usr/bin/python
# -*- coding: utf8 -*-

#  Copyright (C) @2020 Webank Group Holding Limited
#  <p>
#  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
#  in compliance with the License. You may obtain a copy of the License at
#  <p>
#  http://www.apache.org/licenses/LICENSE-2.0
#  <p>
#  Unless required by applicable law or agreed to in writing, software distributed under the License
#  is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
#  or implied. See the License for the specific language governing permissions and limitations under
#  the License.

import errno, logging, socket, os, cPickle, struct, time, re
from stat import ST_DEV, ST_INO, ST_MTIME

try:
    import codecs
except ImportError:
    codecs = None
try:
    unicode
    _unicode = True
except NameError:
    _unicode = False

import sys
import getopt
import os
import subprocess

import logging.handlers as handlers


class LogTimedRotatingFileHandler(handlers.TimedRotatingFileHandler):
    """
    Handler for logging to a set of files, which switches from one file
    to the next when the current file reaches a certain size, or at certain
    timed intervals
    """
    def __init__(self, filename, maxBytes=0, backupCount=0, encoding=None,delay=0, when='h', interval=1, utc=False):
        handlers.TimedRotatingFileHandler.__init__(self, filename, when, interval, backupCount, encoding, delay, utc)
        self.maxBytes = maxBytes
        #set last rollover time
        t = time.strftime('%Y-%m-%d %H',time.localtime(time.time())) + ":00:00"
        timeArray = time.strptime(t, "%Y-%m-%d %H:%M:%S")
        timestamp = int(time.mktime(timeArray))
        self.rolloverAt = self.computeRollover(timestamp)


def usage():
    print 'run.py -c <cmd> -l <log_path>'

def get_logger(log_path):
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    ch = LogTimedRotatingFileHandler(log_path, when='H')
    ch.setLevel(logging.DEBUG)
    formatter = logging.Formatter('%(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    return logger

def shell_exec(cmd_str, log_path):
    res = subprocess.Popen(cmd_str, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
    logger = get_logger(log_path)
    while 1:
        output = res.stderr.readline()
        if output == "":
            break;
        else:
            logger.info(output.strip())

def main(argv):
    cmd = ''
    log_path = ''
    try:
        opts, args = getopt.getopt(argv,"hc:l:",["help","cmd=","log_path="])
    except getopt.GetoptError:
        sys.exit(2)
    for opt, arg in opts:
        if opt in ("-h","--help"):
            usage()
            sys.exit()
        elif opt in ("-c", "--cmd"):
            cmd = arg
        elif opt in ("-l", "--log_path"):
            log_path = arg
    if cmd != '' and log_path != '':
        shell_exec(cmd, log_path)

if __name__ == "__main__":
    main(sys.argv[1:])
