#!/bin/bash
source conf.cfg

ham()
{
   cat >  mariadb.repo << H2
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/rhel7-amd64/
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
H2

scp -i node$1 mariadb.repo root@$2:/etc/yum.repos.d/
ssh -i node$1 root@$2 "setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config"
ssh -i node$1 root@$2 "yum install MariaDB-Galera-server MariaDB-client galera -y"
cat > galera.cnf << H2
[galera]
# Mandatory settings
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address='gcomm://$IP1,$IP2,$IP3'
wsrep_cluster_name='mariadb_cluster'
wsrep_node_address='$2'
wsrep_sst_method=rsync
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0
H2
scp -i node$1 galera.cnf root@$2:/etc/my.cnf.d/
if [ "$1" = "1" ]
then
    ssh -i node$1 root@$2 "/etc/init.d/mysql restart --wsrep-new-cluster"
else
    ssh -i node$1 root@$2 "/etc/init.d/mysql restart"
fi

}
#
for x in $IP1 $IP2 $IP3
do
        list=`cat conf.cfg`
        for i in $list
        do
            y=`echo $i | grep -w "$x"`
            if [ -n "$y" ]
            then
               NODE=`echo $y | awk -F = '{print $1}' | awk -F P {'print $2'}`
               ham $NODE $x
            fi
        done
done



