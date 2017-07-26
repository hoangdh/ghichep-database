#!/bin/bash

set_host()
{
. ./var.cfg
### Write to hosts
echo -e "$IP1 $HOST1
$IP2 $HOST2
$IP3 $HOST3" >> /etc/hosts
### Gen-key
ssh-keygen -t rsa -N "" -f ~/.ssh/hoangdh.key
mv ~/.ssh/hoangdh.key.pub ~/.ssh/authorized_keys
mv ~/.ssh/hoangdh.key ~/.ssh/id_rsa
chmod 600 ~/.ssh/authorized_keys

for ip in $IP1 $IP2 $IP3
do
    NODE=`cat var.cfg | grep -w "$ip" | awk -F = '{print $1}' | awk -F P {'print $2'}`
    HOST=`cat var.cfg | grep -e "HOST$NODE" |  awk -F = '{print $2}'`
    scp -r ~/.ssh/ $HOST:~/
    # hostnamectl set-hostname $HOST -H root@$HOST
    ssh $HOST "hostnamectl set-hostname $HOST"
    echo "Set hostname for host $ip: $NODE - $HOST"
    scp /etc/hosts root@$HOST:/etc/
done
}

setup ()
{
cat >  mariadb.repo << H2
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/rhel7-amd64/
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
H2

scp mariadb.repo root@$1:/etc/yum.repos.d/
ssh root@$1 "setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config"
ssh root@$1 "yum install MariaDB-Galera-server MariaDB-client galera -y"
cat > galera.cnf << H2
[galera]
# Mandatory settings
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address='gcomm://$IP1,$IP2,$IP3'
wsrep_cluster_name='mariadb_cluster'
wsrep_node_address='$1'
wsrep_sst_method=rsync
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0
H2
scp galera.cnf root@$1:/etc/my.cnf.d/
if [ "$2" = "1" ]
then
	
    ssh root@$1 "/etc/init.d/mysql restart --wsrep-new-cluster" 
	ssh root@$1 "mysql -uroot -e \"set password for 'root'@'localhost' = password('$PASSWORD');\""
	ssh root@$1 "mysql -uroot -p$PASSWORD -e \"DELETE from  mysql.user where Password = '';\""
	ssh root@$1 "mysql -uroot -p$PASSWORD -e \"CREATE USER 'root'@'%' IDENTIFIED BY '$PASSWORD';\""
	ssh root@$1 "mysql -uroot -p$PASSWORD -e \"GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';\""
	ssh root@$1 "mysql -uroot -p$PASSWORD -e \"FLUSH PRIVILEGES;\""
	
elif [ "$2" = "2" ]
	then
    ssh root@$1 "/etc/init.d/mysql restart"
	ssh root@$1 "mysql -uroot -e \"set password for 'root'@'localhost' = password('$PASSWORD');\""
	ssh root@$1 "mysql -uroot -p$PASSWORD -e \"DELETE from  mysql.user where Password = '';\""
	ssh root@$1 "mysql -uroot -p$PASSWORD -e \"drop database test;\""
else
	 ssh root@$1 "/etc/init.d/mysql restart"
fi
}

set_host
for x in $IP1 $IP2 $IP3
do
        list=`cat var.cfg`
        for i in $list
        do
            y=`echo $i | grep -w "$x"`
            if [ -n "$y" ]
            then
               NODE=`echo $y | awk -F = '{print $1}' | awk -F P {'print $2'}`
               setup $x $NODE
			   ssh root@$x "chkconfig mysql on"
            fi
        done
done