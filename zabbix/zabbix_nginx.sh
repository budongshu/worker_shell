#!/bin/bash
HOST=`ifconfig| grep -EA 2 "(eth1|em2)"| awk '/inet/{print $2}'| cut -d: -f 2|head -1 ` 
PORT=80
#echo $HOST
#echo $PORT
function ping {
    /sbin/pidof nginx | wc -l 
}
# 检测nginx性能
function active {
    /usr/bin/curl "http://$HOST:$PORT/nginxstatus/" 2>/dev/null| grep 'Active' | awk '{print $NF}'
}
function reading {
    /usr/bin/curl "http://$HOST:$PORT/nginxstatus/" 2>/dev/null| grep 'Reading' | awk '{print $2}'
}
function writing {
    /usr/bin/curl "http://$HOST:$PORT/nginxstatus/" 2>/dev/null| grep 'Writing' | awk '{print $4}'
}
function waiting {
    /usr/bin/curl "http://$HOST:$PORT/nginxstatus/" 2>/dev/null| grep 'Waiting' | awk '{print $6}'
}
function accepts {
    /usr/bin/curl "http://$HOST:$PORT/nginxstatus/" 2>/dev/null| awk NR==3 | awk '{print $1}'
}
function handled {
    /usr/bin/curl "http://$HOST:$PORT/nginxstatus/" 2>/dev/null| awk NR==3 | awk '{print $2}'
}
function requests {
    /usr/bin/curl "http://$HOST:$PORT/nginxstatus/" 2>/dev/null| awk NR==3 | awk '{print $3}'
}
# 执行function
$1
