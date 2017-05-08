#!/bin/bash
echo -e "Huong dan cai dat:
- Chuan bi:
    + SSH-Key cua node 2 voi ten 'node2'
    + Volume Group moi ten centos co dung luong lon hon 1GB
    + Khai bao thong tin vao file var.conf (IP, Node name, VIP, PASSWORD cua hacluster)"
read -p "Bam ENTER de cai dat, CTRL + C de huy bo."

source var.conf
echo -e "$IP1 $HOST1 $HOST1-cr $HOST1-drbd
$IP2 $HOST2 $HOST2-cr $HOST2-drbd
$VIP pcmkvip" >> /etc/hosts
scp -i node2 /etc/hosts root@$HOST2:/etc/
hostnamectl set-hostname $HOST1
ssh -i node2 root@$HOST2 "hostnamectl set-hostname $HOST2"
ssh -i node2 root@$HOST2
echo -e "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
scp -i node2  /etc/sysctl.conf root@$HOST2:/etc/
sysctl -p
ssh -i node2 root@$HOST2 "sysctl -p"
yum install -y pcs
ssh -i node2 root@$HOST2 "yum install -y pcs"
yum install -y policycoreutils-python
ssh -i node2 root@$HOST2 "yum install -y policycoreutils-python"
echo $PASSWORD | passwd hacluster --stdin
ssh -i node2 root@$HOST2 "echo $PASSWORD | passwd hacluster --stdin"
systemctl start pcsd.service && systemctl enable pcsd.service
ssh -i node2 root@$HOST2 "systemctl start pcsd.service && systemctl enable pcsd.service"
pcs cluster auth $HOST1-cr $HOST2-cr -u hacluster -p $PASSWORD
pcs cluster setup --name mysql_cluster $HOST1-cr $HOST2-cr
pcs cluster start --all

#DRBD
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
ssh -i node2 root@$HOST2 "rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org"
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
ssh -i node2 root@$HOST2 "rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm"
yum install -y kmod-drbd84 drbd84-utils
ssh -i node2 root@$HOST2 "yum install -y kmod-drbd84 drbd84-utils"
semanage permissive -a drbd_t
ssh -i node2 root@$HOST2 "semanage permissive -a drbd_t"

## Chuan bi VG co ten 'centos' dung luong 1GB

lvcreate --name lv_drbd --size 1024M centos
ssh -i node2 root@$HOST2 "lvcreate --name lv_drbd --size 1024M centos"

cat << EOL >/etc/drbd.d/mysql01.res
resource mysql01 {
 protocol C;
 meta-disk internal;
 device /dev/drbd0;
 disk   /dev/centos/lv_drbd;
 handlers {
  split-brain "/usr/lib/drbd/notify-split-brain.sh root";
 }
 net {
  allow-two-primaries no;
  after-sb-0pri discard-zero-changes;
  after-sb-1pri discard-secondary;
  after-sb-2pri disconnect;
  rr-conflict disconnect;
 }
 disk {
  on-io-error detach;
 }
 syncer {
  verify-alg sha1;
 }
 on $HOST1 {
  address  $IP1:7789;
 }
 on HOST2 {
  address  $IP2:7789;
 }
}
EOL
scp -i node2 /etc/drbd.d/mysql01.res root@$HOST2:/etc/drbd.d/
drbdadm create-md mysql01
ssh -i node2 root@$HOST2 "drbdadm create-md mysql01"
drbdadm up mysql01
ssh -i node2 root@$HOST2 "drbdadm up mysql01"
drbdadm primary --force mysql01
drbd-overview
mkfs.ext4 -m 0 -L drbd /dev/drbd0
tune2fs -c 30 -i 180d /dev/drbd0
mount /dev/drbd0 /mnt

# Cai dat MariaDB
yum install -y mariadb-server mariadb
ssh -i node2 root@$HOST2 "yum install -y mariadb-server mariadb"
systemctl disable mariadb.service
ssh -i node2 root@$HOST2 "systemctl disable mariadb.service"
systemctl start mariadb
mysql_install_db --datadir=/mnt --user=mysql
semanage fcontext -a -t mysqld_db_t "/mnt(/.*)?"
restorecon -Rv /mnt
umount /mnt
systemctl stop mariadb

cat << EOL > /etc/my.cnf
[mysqld]
symbolic-links=0
bind_address            = 0.0.0.0
datadir                 = /var/lib/mysql
pid_file                = /var/run/mariadb/mysqld.pid
socket                  = /var/run/mariadb/mysqld.sock

[mysqld_safe]
bind_address            = 0.0.0.0
datadir                 = /var/lib/mysql
pid_file                = /var/run/mariadb/mysqld.pid
socket                  = /var/run/mariadb/mysqld.sock

!includedir /etc/my.cnf.d
EOL
scp -i node2 /etc/my.cnf root@$HOST2:/etc/

# Cau hinh cluster

pcs cluster cib clust_cfg
pcs -f clust_cfg property set stonith-enabled=false
pcs -f clust_cfg property set no-quorum-policy=ignore
pcs -f clust_cfg resource defaults resource-stickiness=200

pcs -f clust_cfg resource create mysql_data01 ocf:linbit:drbd drbd_resource=mysql01 op monitor interval=30s
pcs -f clust_cfg resource master MySQLClone01 mysql_data01 master-max=1 master-node-max=1 clone-max=2  clone-node-max=1 notify=true
pcs -f clust_cfg resource create mysql_fs01 Filesystem   device="/dev/drbd0" directory="/var/lib/mysql" fstype="ext4"
pcs -f clust_cfg constraint colocation add mysql_fs01 with MySQLClone01 INFINITY with-rsc-role=Master
pcs -f clust_cfg resource create mysql_service01 ocf:heartbeat:mysql  binary="/usr/bin/mysqld_safe" config="/etc/my.cnf" datadir="/var/lib/mysql" pid="/var/lib/mysql/mysql.pid" socket="/var/lib/mysql/mysql.sock" additional_parameters="--bind-address=0.0.0.0" op start timeout=60s op stop timeout=60s op monitor interval=20s timeout=30s
pcs -f clust_cfg constraint colocation add mysql_service01 with mysql_fs01 INFINITY
pcs -f clust_cfg constraint order mysql_fs01 then mysql_service01
pcs -f clust_cfg resource create mysql_VIP01 ocf:heartbeat:IPaddr2 ip=$VIP cidr_netmask=32 op monitor interval=30s
pcs -f clust_cfg constraint colocation add mysql_VIP01 with mysql_service01 INFINITY
pcs -f clust_cfg constraint order mysql_service01 then mysql_VIP01
pcs -f clust_cfg constraint
pcs -f clust_cfg resource show
pcs cluster cib-push clust_cfg
pcs status