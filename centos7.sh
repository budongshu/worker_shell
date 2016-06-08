# centos 7  初始化脚本安装


# set DNS
echo 'nameserver 223.5.5.5'>/etc/resolv.conf
echo 'nameserver 202.106.0.20'>>/etc/resolv.conf
mkdir -p /data/{sh,soft,applogs,backup}

#service configuration
echo '/usr/sbin/ntpdate cn.pool.ntp.org'>>/etc/rc.local
echo '/sbin/hwclock'>>/etc/rc.local
echo '* */3 * * * /usr/sbin/ntpdate cn.pool.ntp.org>/dev/null 2>&1'>>/var/spool/cron/root

yum install -y wget vim ntpdate net-tools lrzsz gcc pcre-devel openssl-devel openssh 

ntpdate  cn.pool.ntp.org
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

#config ssh
/bin/cp /etc/ssh/sshd_config /etc/ssh/sshd_config.`date +%F-%T`
sed -i 's/#Port 22/Port 60777/g' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
systemctl restart sshd.service

# set iptables
systemctl stop firewalld.service
systemctl disable firewalld.service

# set env 
echo "export HISTTIMEFORMAT='%F-%T '">>/etc/profile
source /etc/profile
#afer cobbler install ini over-------------------------------
alias grep="grep --color"

#set autokey
mkdir -p /root/.ssh
cat >>/root/.ssh/authorized_keys<<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA4ZDf/Ge26kwvFFk4EQf2L6aarZU7dXbRK9NEOTkeAfHN+PT+8YlGKqXl09nxEzs5UAPuk6nhxLpnGkw3aM84TogaiqdGAGmBnzDDCrVX95YB430yl2gbviEDvu8uDZqKMuESyiGFvDVzmTleSao6fUXVZbEZ5VFrvVEP7olg9ffjUtyNQdNd1VgI/8ufsb6u26jC0Nsbp0m2/iG1AxsJHAdQnzeR1o1fspNRhJP+y49cTUfnHTO/KQThHFIfzdQcfULfanHre+4sc28kYxBfR3Orqb/V2+FFVVtzFcAEuFEwRTxP/S/90o4vKYlfMQTRc3i/aHXsAnsnio9nxSbGLw== root@web01
EOF
chmod 600 -R /root/.ssh


#set hostname
#host=$1
#hostname $host
#echo "127.0.0.1 $host" >>/etc/hosts
#echo "$host" > /etc/hostname     


#set limits
#文件打开数
cat > /etc/security/limits.conf << EOF
* soft nofile 1000000
* hard nofile 1000000
EOF


#set sysctl.conf
#true > /etc/sysctl.conf
cat >> /etc/sysctl.conf << EOF
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 1024 65535
EOF
/sbin/sysctl -p
# install  zabbix 
rpm -ivh  http://10.10.10.180/rpmpkg/zabbix-agent-2.2.7-2.el7.x86_64.rpm  
sed -i 's@Server=127.0.0.1@Server=10.10.10.74@g' /etc/zabbix/zabbix_agentd.conf
sed -i 's@ServerActive=127.0.0.1@#ServerActive=127.0.0.1@g' /etc/zabbix/zabbix_agentd.conf
sed -i 's@Hostname=Zabbix server@Hostname='`ifconfig  em1 | awk '/inet/{print $2 }' | grep -E '^[1-9|2-9]'`'@g' /etc/zabbix/zabbix_agentd.conf
systemctl start zabbix-agent.service 
systemctl enable zabbix-agent.service
ss -tunlp 
