#!/bin/bash

set -e


NGINX_HOME=/home/work/nginx
NGINX_BIN=/usr/sbin/nginx
PID_FILE=/home/work/nginx/var/nginx.pid
NGINX_CONF=/home/work/nginx/conf/nginx.conf
NGINX_LOG="access_log error_log"

not() {
    if $@; then
        return 1;
    else
        return 0;
    fi
}

wait_for() {
    local try=$1
    shift
    for ((;try>0;try--)); do
        if $@ ; then
            return 0
        fi
        echo -n .
        sleep 1
    done
    return 1
}

process_exists() {
    local pid=$1
    local bin=$2
    if [[ -d /proc/$pid ]]; then
        local exe=`readlink -f /proc/$pid/exe`
        if [[ $exe == $bin ]]; then
            return 0
        fi
        # ????ODPĿ¼???ƶ??????
        if [[ ! -e $exe ]]; then
            return 0
        fi
    fi
    return 1
}

start() {
    echo -n "Starting nginx: "
    
    if [ ! -d "/home/work/nginx/logs" ]
    then
        mkdir "/home/work/nginx/logs"
    fi
    if [ ! -d "/home/work/nginx/cache" ]
    then
        mkdir "/home/work/nginx/cache"
    fi
    if [ ! -d "/home/work/nginx/var/" ]
    then
        mkdir "/home/work/nginx/var/"
    fi

    if $NGINX_BIN -c $NGINX_CONF </dev/null; then
        echo "ok"
    else
        echo "fail"
    fi
}

stop() {
    if [[ ! -f $PID_FILE ]]; then
        return
    fi
    PID=`head $PID_FILE`
    if ! process_exists $PID $NGINX_BIN; then
        echo  "no process found, just remove pid file"
        rm $PID_FILE
        return
    fi
    echo -n "Stopping nginx: "
    kill $PID
    if wait_for 10 " process_exists $PID $NGINX_BIN"; then
        echo 'ok'
    else
        echo 'fail'
        exit 1
    fi
}


case "$1" in
start)
    stop
    start
    ;;

stop)
    stop
    ;;

restart)
    stop
    start
    ;;

reload)
    if $NGINX_BIN -s reload; then
        echo  "reload ok, please check it youself";
    else
        echo "reload fail"
    fi
    ;;

chkconfig)
    GCONV_PATH=$ODP_GCONV_PATH $NGINX_BIN -t
    ;;

*)
echo "Usage: $0 {start|stop|restart|chkconfg|reload}"
exit 1
esac
