#!/bin/bash

function zabbix() {

#編譯安裝
wget http://sourceforge.net/projects/zabbix/files/ZABBIX%20Latest%20Stable/2.2.6/zabbix-2.2.6.tar.gz/
tar xf zabbix-2.2.6.tar.gz
cd /root/zabbix-2.2.6
./configure --prefix=/usr/local/zabbix --enable-server --enable-agent --enable-proxy --with-mysql --enable-ipv6 --with-net-snmp \
--with-libcurl --with-libxml2--with-openipmi --with-unixodbc --with-jabber
make && make install 

#導入數據庫
useradd zabbix
cd  /root/zabbix-2.2.6/database/mysql
mysql  -h127.0.0.1 -uzabbix -pzabbixpass zabbix < schema.sql      
mysql  -h127.0.0.1 -uzabbix -pzabbixpass zabbix < images.sql 
mysql  -h127.0.0.1 -uzabbix -pzabbixpass zabbix < data.sql

#php.ini
sed -i "/date.timezone =/c date.timezone = 'Asia/Shanghai'" /etc/php.ini 
sed -i '/post_max_size = /c post_max_size = 30M' /etc/php.ini
sed -i '/max_input_time = /c max_input_time = 300' /etc/php.ini
sed -i '/max_execution_time =/c max_execution_time = 300' /etc/php.ini

#增加服务端口
cat >>/etc/services <<EOF
zabbix-agent   10050/tcp #Zabbix Agent
zabbix-agent   10050/udp #Zabbix Agent
zabbix-trapper 10051/tcp #Zabbix Trapper
zabbix-trapper 10051/udp #Zabbix Trapper
EOF

#配置zabbix_server
sed -i "/DBHost=localhost/c DBHost=127.0.0.1" /usr/local/zabbix/etc/zabbix_server.conf 
sed -i "/DBName=zabbix/c DBName=zabbix" /usr/local/zabbix/etc/zabbix_server.conf
sed -i "/DBUser=root/c DBUser=zabbix" /usr/local/zabbix/etc/zabbix_server.conf
sed -i "/DBPassword=/c DBPassword=zabbixpass" /usr/local/zabbix/etc/zabbix_server.conf


#配置啟動腳本 
cd /root/zabbix-2.2.6/
cp misc/init.d/fedora/core5/* /etc/init.d/
chmod +x /etc/init.d/zabbix_*
sed  -i  's@\(ZABBIX_BIN\)="/usr/local/sbin/zabbix_server"@\1="/usr/local/zabbix/sbin/zabbix_server"@g' /etc/init.d/zabbix_server
sed  -i  's@\(ZABBIX_BIN\)="/usr/local/sbin/zabbix_agentd"@\1="/usr/local/zabbix/sbin/zabbix_agentd"@g' /etc/init.d/zabbix_agentd

/etc/init.d/zabbix_server start
chkconfig  zabbix_server on
/etc/init.d/php-fpm reload
/etc/init.d/mysqld reload 
/etc/init.d/nginx reload 
}
 
cat >> /data/application/nginx/conf/vhosts/zabbix.conf <<EOF 
server{
   listen       80;
   server_name bds.zabbix.com;
   index index.php;
   root /data/code/zabbix;
   #access_log /data/logs/nginx/zabbix_access.log fenxi:
   error_log  /data/logs/nginx/zabbix_error.log ;
   location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
       expires 30d;
   }
   location ~* \.php$ {
       fastcgi_pass   127.0.0.1:9000;
       fastcgi_index  index.php;
       fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
       include        fastcgi_params;
   }
}
EOF
mkdir /data/code/zabbix 
cd /data/code/zabbix 
cp -a /root/zabbix-2.2.6/frontends/php/* . 
chown www.www /data/code/* -R 
