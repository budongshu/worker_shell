#!/bin/bash
#description: centos6 init shell

##dns
echo 'nameserver 223.5.5.5'>/etc/resolv.conf
echo 'nameserver 202.106.0.20'>>/etc/resolv.conf
mkdir -p /data/sh

#service configuration
echo '/usr/sbin/ntpdate cn.pool.ntp.org'>>/etc/rc.local
echo '/sbin/hwclock'>>/etc/rc.local
/etc/init.d/ntpd stop
chkconfig ntpd off
ntpdate  cn.pool.ntp.org
echo '* */3 * * * /usr/sbin/ntpdate cn.pool.ntp.org>/dev/null 2>&1'>>/var/spool/cron/root
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

yum install -y ntpdate  rsync  wget bc sysstat 
for service in `chkconfig --list|awk '{print $1}'|egrep -v "^$"|awk -F ":" '{print $1}'`;do chkconfig $service off;done
for service in atd  crond sshd irqbalance  kdump messagebus rpcbind  rsyslog sysstat udev-post network;do chkconfig $service on;done

#config ssh
/bin/cp /etc/ssh/sshd_config /etc/ssh/sshd_config.`date +%F-%T`
sed -i 's/#Port 22/Port 60777/g' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
/etc/init.d/sshd restart

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
Host=$1
hostname $Host
echo "127.0.0.1 $Host" >>/etc/hosts
sed -i "/HOSTNAME/s/localhost.*/$Host/" /etc/sysconfig/network

#set limits
cat > /etc/security/limits.conf << EOF
* soft nofile 1000000
* hard nofile 1000000
EOF

#修改启动模式/etc/inittab
sed -i  '/initdefault/s/id:5/id:3/' /etc/inittab 

#disable ipv6 关闭IPv6
echo "alias net-pf-10 off" >> /etc/modprobe.d/ipv6.conf
echo "options ipv6 disable=1" >> /etc/modprobe.d/ipv6.conf
echo "NETWORKING_IPV6="no"" >>  /etc/sysconfig/network
/sbin/chkconfig --level 35 ip6tables off
echo "ipv6 is disabled!"

##client
sed -i -e '44 s/^/#/' -i -e '48 s/^/#/' $ssh_cf

#set sysctl.conf
true > /etc/sysctl.conf
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

#echo "/data/sh/$Rfile" >>/etc/rc.local 
##############################################
#set route
net=`ip a|sed -n '6p'|awk -F ":" '{print $2}'|awk '{print $1}'`
route add -net 10.10.30.0 netmask 255.255.255.0 $net
route add -net 10.10.40.0 netmask 255.255.255.0 $net
route add -net 10.10.50.0 netmask 255.255.255.0 $net
route add -net 10.10.60.0 netmask 255.255.255.0 $net
route add -net 10.10.70.0 netmask 255.255.255.0 $net
route add -net 10.10.80.0 netmask 255.255.255.0 $net
route add -net 10.10.90.0 netmask 255.255.255.0 $net
route add -net 10.10.100.0 netmask 255.255.255.0 $net
route add -net 10.10.110.0 netmask 255.255.255.0 $net

cat>>/data/sh/addroute.sh<<EOF
net=`ip a|sed -n '6p'|awk -F ":" '{print $2}'|awk '{print $1}'`
route add -net 10.10.20.0 netmask 255.255.255.0 $net
route add -net 10.10.30.0 netmask 255.255.255.0 $net
route add -net 10.10.40.0 netmask 255.255.255.0 $net
route add -net 10.10.50.0 netmask 255.255.255.0 $net
route add -net 10.10.60.0 netmask 255.255.255.0 $net
route add -net 10.10.70.0 netmask 255.255.255.0 $net
route add -net 10.10.80.0 netmask 255.255.255.0 $net
route add -net 10.10.90.0 netmask 255.255.255.0 $net
route add -net 10.10.100.0 netmask 255.255.255.0 $net
route add -net 10.10.110.0 netmask 255.255.255.0 $net
EOF
#echo "/bin/sh /data/sh/addroute.sh &>/dev/null">>/etc/rc.local
cat << EOF
+-------------------------------------------------+
|               optimizer is done                               |
|   it's recommond to restart this server !             |
+-------------------------------------------------+
EOF
