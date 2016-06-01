#!/bin/bash
Getip=$(curl -s ip.cn?ip=$1)

IParea=$(echo $Getip|awk -F "：" '{print $3}'|awk '{print $1}')

IPisp=$(echo $Getip|awk -F "：" '{print $3}'|awk '{print $2}')

if [ ! $1 ];then

IP=$(echo $Getip|awk -F "：" '{print $2}'|awk '{print $1}')

echo $IP $IParea $IPisp

else

echo $1 $IParea $IPisp

fi
