#!/usr/bin/bash
if [ $# -lt 1 ]
then
  echo "Usage: $0 [19 | 18]
        #18 - SIGCONT, 19 - SIGSTOP"
  exit -1
fi

SIGNAL=$1

ps -eaf|grep io500|egrep -v "io500.sh|mpiexec|pfind|find_script|grep"|awk '{print $2}'|xargs kill -${SIGNAL}
