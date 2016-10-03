#!/bin/bash

setup_Centos()
{
    yum -y install centos-release-scl-rh centos-release-scl
    sed -i -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/CentOS-SCLo-scl.repo
    sed -i -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo
    yum --enablerepo=centos-sclo-rh -y install rh-mariadb101-mariadb-server 
    scl enable rh-mariadb101 bash
        cat > /etc/profile.d/rh-mariadb101.sh  << H2
#!/bin/bash

source /opt/rh/rh-mariadb101/enable
export X_SCLS="`scl enable rh-mariadb101 'echo $X_SCLS'`"
H2
    yum --enablerepo=centos-sclo-rh -y install rh-mariadb101-mariadb-server-galera
    # firewall-cmd --add-service=mysql --permanent
    # firewall-cmd --add-port={3306/tcp,4567/tcp,4568/tcp,4444/tcp} --permanent
    # firewall-cmd --reload
    systemctl restart rh-mariadb101-mariadb
    systemctl enable rh-mariadb101-mariadb
    mysql -uroot -p -e "UPDATE mysql.user SET Password=PASSWORD('$PASSWORD') WHERE User='root';
                        DELETE FROM mysql.user WHERE User='';
                        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
                        DROP DATABASE IF EXISTS test;
                        DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
                        FLUSH PRIVILEGES;"
    systemctl restart rh-mariadb101-mariadb
     mysql -uroot -p$PASSWORD -e "show databases;"
}

configure_n1_centos()
{
    mv /etc/opt/rh/rh-mariadb101/my.cnf.d/galera.cnf /etc/opt/rh/rh-mariadb101/my.cnf.d/galera.cnf.org
    cat > /etc/opt/rh/rh-mariadb101/my.cnf.d/galera.cnf << H2
[galera]
# Mandatory settings
wsrep_on=ON
wsrep_provider=/opt/rh/rh-mariadb101/root/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address=gcomm://

binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

wsrep_cluster_name="MariaDB_Cluster"
wsrep_node_address="$1"
wsrep_sst_method=rsync
H2
    /opt/rh/rh-mariadb101/root/usr/bin/galera_new_cluster
}

configure_centos(){
    mv /etc/opt/rh/rh-mariadb101/my.cnf.d/galera.cnf /etc/opt/rh/rh-mariadb101/my.cnf.d/galera.cnf.org
    cat > /etc/opt/rh/rh-mariadb101/my.cnf.d/galera.cnf << H2
[galera]
# Mandatory settings
wsrep_on=ON
wsrep_provider=/opt/rh/rh-mariadb101/root/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://$IP1,$IP2,$IP3"

binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

wsrep_cluster_name="MariaDB_Cluster"
wsrep_node_address="$1"
wsrep_sst_method=rsync
H2
    systemctl restart rh-mariadb101-mariadb
}

run()
{
for x in $IP1 $IP2 $IP3
do
    tmp=$(ip a | grep -w "$x")
    if [ -n "$tmp" ]
    then
       IP=$x
   fi   
done
list=`cat conf.cfg`
for i in $list
do
    y=`echo $i | grep -w "$IP"`
    if [ -n "$y" ]
    then
       NODE=`echo $y | awk -F = '{print $1}' | awk -F P {'print $2'}`
    fi
done
if [ -n "$NODE" ] && [ -n "$IP" ]
then
    echo "NODE $NODE has IP address: $IP"
     
case $NODE in
    1)
            setup_Centos
            configure_n1_centos $IP
            ;;
         
    *)
            setup_Centos
            configure_centos $IP
            ;;
esac
else
    echo "Invaild node!"
fi
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
        read -p "Enter IP Node 1: " IP1
        read -p "Enter IP Node 2: " IP2
        read -p "Enter IP Node 3: " IP3
        read -p -s "Enter password for MySQL's root: " pass1
        while true
        do
            read -p -s $'\Re-Enter password for MySQL\'s root: ' pass2
            if [ "$pass1" = "$pass2" ]
            then
            break
            else
                echo "Not match!"
            fi
        done
            
cat > conf.cfg << H2
export PASSWORD=$pass2
export IP1=$IP1
export IP2=$IP2
export IP3=$IP3
H2
        fi     

}

main