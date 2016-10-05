#!/bin/bash

# Add repo and setup MySQL Galera WSREP

setup_Ubuntu()
{
    apt-key adv --keyserver keyserver.ubuntu.com --recv  44B7345738EBDE52594DAD80D669017EBC19DDBA
    add-apt-repository 'deb [arch=amd64,i386] http://releases.galeracluster.com/ubuntu/ xenial main'
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
    apt-get update
    apt-get install -y galera-3 galera-arbitrator-3 mysql-wsrep-5.6 rsync
}

# Configuring the Galera

configure_Galera()
{
    cat > /etc/mysql/conf.d/galera.cnf << H2
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
wsrep_node_address="$1"
wsrep_node_name="Galera_Node_$2"
H2
    sed -e '/bind-address/ s/^#*/#/g' /etc/mysql/my.cnf
    ufw allow 3306,4567,4568,4444/tcp
    ufw allow 4567/udp
    systemctl stop mysql
}

# Start the node 1 on Ubuntu

start_node1_Ubuntu()
{
     /etc/init.d/mysql start --wsrep-new-cluster
     mysql -uroot -p$PASSWORD -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
     mysql -uroot -p$PASSWORD -e "update mysql.user set password=PASSWORD('03P8rdlknkXr1upf_H2') where User='debian-sys-maint';"
}

# Start the remain nodes on Ubuntu

start_Ubuntu()
{
     systemctl start mysql
     mysql -uroot -p$PASSWORD -e "update mysql.user set password=PASSWORD('03P8rdlknkXr1upf_H2') where User='debian-sys-maint';"
     mysql -uroot -p$PASSWORD -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
     sleep 3
}

# Configuring the Debian Maintenance User

create_DMU()
{
    cat > /etc/mysql/debian.cnf << H2
[client]
host     = localhost
user     = debian-sys-maint
password = 03P8rdlknkXr1upf_H2
socket   = /var/run/mysqld/mysqld.sock
[mysql_upgrade]
host     = localhost
user     = debian-sys-maint
password = 03P8rdlknkXr1upf_H2
socket   = /var/run/mysqld/mysqld.sock
basedir  = /usr
H2
     mysql -udebian-sys-maint -p03P8rdlknkXr1upf_H2 -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
     sleep 3
}

run()
{
read -p "What node you want install Galera?: " NODE;
case $NODE in
    1)
            setup_Ubuntu
            configure_Galera $IP1 $NODE
            create_DMU
            start_node1_Ubuntu
            ;;
         
    2)
            setup_Ubuntu
            configure_Galera $IP2 $NODE
            create_DMU
            start_Ubuntu
            ;;
         
    3)
            setup_Ubuntu
            configure_Galera $IP3 $NODE
            create_DMU
            start_Ubuntu
            create_DMU
            ;;
    *)
           echo "Invaild input!"
            ;;
esac 
}

main()
{
        file="conf.cfg"
        if [ -f "$file" ]
        then
            clear
            echo "$file found."
            . conf.cfg
            echo -e "--------INFO---------
        Node1: $IP1
        Node2: $IP2
        Node3: $IP3
        Password: $PASSWORD
        ----------------------"
        run
        else
        echo Please fill info in file 'conf.cfg'!
cat > conf.cfg << H2
export PASSWORD=Abcdef@6789
export IP1=1.1.1.1
export IP2=2.2.2.2
export IP3=3.3.3.3
H2
         vi conf.cfg
        fi
       

}

main