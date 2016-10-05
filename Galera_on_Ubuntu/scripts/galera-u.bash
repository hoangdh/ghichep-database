#!/bin/bash

cauhinhchung()
{
    ssh -i node$1 root@$2 "apt-key adv --keyserver keyserver.ubuntu.com --recv  44B7345738EBDE52594DAD80D669017EBC19DDBA"
    ssh -i node$1 root@$2 "add-apt-repository 'deb [arch=amd64,i386] http://releases.galeracluster.com/ubuntu/ xenial main'"
    ssh -i node$1 root@$2 "debconf-set-selections <<< \"mysql-server mysql-server/root_password password $PASSWORD\""
    ssh -i node$1 root@$2 "debconf-set-selections <<< \"mysql-server mysql-server/root_password_again password $PASSWORD\""
    ssh -i node$1 root@$2 "apt-get update && apt-get install -y galera-3 galera-arbitrator-3 mysql-wsrep-5.6 rsync"
    
     cat > galera.cnf << H2
[mysqld]
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="test_cluster"
wsrep_cluster_address="gcomm://$IP1,$IP2,$IP3"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="$2"
wsrep_node_name="Galera_Node_$1"
H2
    scp -i node$1 galera.cnf root@$2:/etc/mysql/conf.d/
    ssh -i node$1 root@$2 "sed -e '/bind-address/ s/^#*/#/g' /etc/mysql/my.cnf"
    ssh -i node$1 root@$2 "ufw allow 3306,4567,4568,4444/tcp && ufw allow 4567/udp && /etc/init.d/mysql stop"
       
    # ssh -i node$1 root@$2
    # ssh -i node$1 root@$2
}

khoidongnode1()
{
    scp -i node$1 root@$2:/etc/mysql/debian.cnf .
    ssh -i node$1 root@$2 "/etc/init.d/mysql start --wsrep-new-cluster"    
}

khoidongnodekhac()
{
     scp -i node$1 debian.cnf root@$2:/etc/mysql/
     ssh -i node$1 root@$2 "/etc/init.d/mysql start"
     if [ "$1" = "3" ]
     then
           ssh -i node$1 root@$2 "mysql -uroot -p$PASSWORD -e \"SHOW STATUS LIKE 'wsrep_cluster_size'\""
     fi
}

. var.cfg
for ip in $IP1 $IP2 $IP3
do
    NODE=`cat var.cfg | grep -w "$ip" | awk -F = '{print $1}' | awk -F P {'print $2'}`
    if [ "$NODE" = "1" ]
    then
        echo "Cai dat Node $NODE"
        cauhinhchung $NODE $ip
        khoidongnode1 $NODE $ip
    else
         echo "Cai dat Node $NODE"
         cauhinhchung $NODE $ip
         khoidongnodekhac $NODE $ip       
    fi
done 