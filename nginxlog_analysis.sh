#!/bin/bash
# 联系人: 步东舒
# data: 2016.4.6
# web日志分析脚本

##使用帮助
usage()

{
	
	echo -e "----------------------------------------------------------------------  "
	echo -e "   "
	echo -e "   "
	echo -e "第一种查询当前现在的日志"
	echo -e "   "
	echo -e "   使用: $0   nowlog(加上nowlog参数) "
	echo -e "    "
	echo -e "----------------------------------------------------------------------  "
	echo -e "第二种查询半个小时过去的日志"
        echo -e "   Usage:$0 [-c n] [-t n] -f FILE\n"
        echo -e "   选项说明:"
        echo -e "   	-c(选填):设置IP、资源TOP榜显示量，默认显示前5名，参数需填写整数"
        echo -e "   	-t(选填):设置日志统计时段，默认统计最后6个时段，参数需填写整数"
        echo -e "   例：$0 "
        echo -e "   或：$0 -c 3 -t 3 \n" 
        exit
}
##华丽的分割线
split_line="--------------------------------------------------"
clear
##审核选项
while getopts ":hc:t:" script_opt
do
        case ${script_opt} in
                h)
                time_hz=half
		usage
                ;;
                c)
                if [[ ${OPTARG} =~ ^[1-9][0-9]*$ ]];then
                        ip_row=${OPTARG}
                else
                        echo -e "\033[31mErr: -c选项请填写整数TOP榜显示行\033[0m"
                        usage
                fi
                ;;
                t)
                if [[ ${OPTARG} =~ ^[1-9][0-9]*$ ]];then
                        log_time=${OPTARG}
                else
                        echo -e "\033[31mErr: -t选项请填写整数时段\033[0m"
                        usage
                fi ;;
                :)
                echo -e "\033[31mErr: -${OPTARG}选项缺少参数，请核实！\033[0m"
                usage
                ;;
                ?)
                echo -e "\033[31mErr: 无法识别的选项，请核实！\033[0m"
                usage
                ;;
        esac
done

#变量设置
Nowtime=`date "+%Y%m%d %H:%M"`
echo $time 
Interval=30
logpath=/data/applogs/nginxlogs/backuplog

#判断时间,把时间变成整数时间格式
iftime() { 
	value1=`echo $Nowtime | awk -F : '{print $1}'`
	value2=`echo $Nowtime | awk -F : '{print $2}'`
	if    [ $value2 -ge 30 ];then 
		#echo ">30"
		time=${value1}:30
	elif  [ $value2 -lt 30  ] ;then
		#echo "<30" 
		time=${value1}:00
		echo $time 
	fi 
	
}
#检测文件
checklog() { 
##检测日志文件大小
log_size=$(du -m "$1"|awk '{print $1}')
if [ "${log_size}" -gt 150 ];then
        echo -e "日志文件:$1\t大小:${log_size}MB\n日志文件体积较大，分析时间较长，是否继续?"
        read -p"yes[y] or no[n]:" -n 1 check_size
        if [ "${check_size}" = "y" ];then
        echo -e "\n正在分析，请稍等..."
        else
        echo -e "\n终止日志分析"
        exit
        fi
elif [ "${log_size}" -eq 0 ];then
        echo -e "日志文件:$1\t大小:${log_size}MB\n\033[31m日志文件为空，请选择其他日志\033[0m"
        usage
fi
}
getip() { 
	Getip=$(curl -s ip.cn?ip=$1)
	IParea=$(echo $Getip|awk -F "：" '{print $3}'|awk '{print $1}')
	IPisp=$(echo $Getip|awk -F "：" '{print $3}'|awk '{print $2}')
	if [ ! $1 ];then
		IP=$(echo $Getip|awk -F "：" '{print $2}'|awk '{print $1}')
		echo $IP $IParea $IPisp
	
	else
		echo $1 $IParea $IPisp
fi	
}
Nowlog() { 
		
	cd /data/applogs/nginxlogs/
	echo "$Nowtime nginx log 分析如下: "
	topip=$(awk '{print $1 }' access.log|sort |uniq -c|sort -rn|head -5 > /root/now_nginxlog.txt)  
	url=$(awk '{if($10>0 )print $7}' access.log |sort|uniq -c|sort -rn|head -5 >> /root/now_nginxlog.txt )
	cat /root/now_nginxlog.txt	
}
total() { 
   Number=${log_time:-5}
   echo "Num: $Number"
   for i in `seq 1 ${Number}`
   do 	
	cd $logpath 
	timeformat=`echo  "$time" | sed -r 's@(.{6})(.{2}) (.{2}):(.{2})$@\1\2_\3\4@g' `
	count=$(($i * $Interval))
	agotime=`date -d "$time $count minutes ago" +%Y%m%d_%H%M`
	searchlog=`find . -name "access.log-${agotime}*" -type f` 
	echo $searchlog 
	net_size=$(awk '{if($10 ~ /[0-9]/) sum += $10} END {printf("%0.2f\n",sum/1024/1024)}' $searchlog )
	top_ip=$(awk '{print $1}' $searchlog |sort |uniq -c|sort -rn|head -n ${ip_row:-5})	 
	top_page=$(awk '{if($10>0 )print $7}' $searchlog |sort|uniq -c|sort -rn|head -n ${ip_row:-5})
	checklog "$searchlog"
	#for_topip "${top_ip}"
	echo -e "${split_line}\n${timeformat}   本时段流量:${net_size} MB"
        echo -e "  次数 访问者IP"
        echo -e "${top_ip}"
        echo -e "  次数 访问资源"
        echo -e "${top_page}"
   done
} 
main() { 
	iftime
	total  
}
case $1 in 
nowlog) 
    Nowlog;;	
*)
    main;;
esac 
