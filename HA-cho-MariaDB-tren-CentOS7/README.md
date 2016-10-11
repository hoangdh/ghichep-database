## Hướng dẫn cấu hình HA cho MariaDB sử dụng Pacemaker+Corosync và DRBD trên CentOS 7

*Chúng ta sẽ sử dụng 2 node Active/Passive cho MariaDB HA cluster sử dụng Pacemaker+Corosync*

[1. Chuẩn bị ](#1)

- [1.1. Môi trường cài đặt](#1.1)
- [1.2. Thiết lập IP cho các node](#1.2)
- [1.3. Mô hình](#1.3)

[2. Các bước tiến hành](#2)

- [2.1 Thêm thông tin các node vào file hosts](#2.1)
- [2.2 Cài đặt Pacemaker và Corosync](#2.2)
- [2.3 Cấu hình Corosync](#2.3)
- [2.4 Cài đặt DRBD và MariaDB](#2.4)
    - [2.4.1 DRBD ](#2.4.1)
    - [2.4.2 Tạo LVM Volume cho DRBD ](#2.4.2)
    - [2.4.3 Cấu hình DRBD ](#2.4.3)
    - [2.4.4 MariaDB ](#2.4.4)
- [2.5 Cấu hình pacemaker ](#2.5)

[3. Tham khảo](#3)

<a name="1"></a>
## 1. Chuẩn bị

<a name="1.1"></a>
### 1.1. Môi trường cài đặt

```
[root@pcmk01 ~]# cat /etc/redhat-release
CentOS Linux release 7.2.1511 (Core)
[root@pcmk01 ~]# uname -a
Linux pcmk01.hoang.lab 3.10.0-327.28.3.el7.x86_64 #1 SMP Tue Oct 11 8:35:45 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
```

Chuẩn bị một Volume Group để lưu trữ các file đồng bộ từ drbd. (Dung lượng tùy theo kích cỡ DB của bạn, trong bài hướng dẫn tôi có một Volume Group có dung lượng trống lớn hơn 1GB. Nếu chưa rõ về khái niệm này, vui lòng đọc hướng dẫn tại  <a href="https://github.com/hoangdh/Su_dung_LVM">đây</a> .)

<a name="1.2"></a>
### 1.2. Thiết lập IP và hostname cho các node

```
VIP: 192.168.100.123
```

```
IP:
Node 1: 192.168.100.196 - Hostname: pcmk01.hoang.lab
Node 2: 192.168.100.197 - Hostname: pcmk02.hoang.lab

GATEWAY: 192.168.100.1
NETWORK: 192.168.100.0/24
```

<a name="1.3"></a>
### 1.3. Mô hình

<img width=75% src="https://camo.githubusercontent.com/bf6d9f67c22c5f4944f5fa334789e63ca5d5c64c/687474703a2f2f696d6167652e70726e747363722e636f6d2f696d6167652f37653965316132366537656634623630393361663633383434393135303532652e706e67" />

<a name="2"></a>
## 2. Các bước thực hiện

<a name="2.1"></a>
### 2.1. Thêm thông tin các node vào file `hosts` của 2 node

```
vi /etc/hosts
```

```
...
192.168.100.196 pcmk01 pcmk01-cr pcmk01-drbd
192.168.100.197 pcmk02 pcmk02-cr pcmk02-drbd
```

Đặt hostname cho 2 node

Trên node 1:

```
hostnamectl set-hostname pcmk01
```

Trên node 2:

```
hostnamectl set-hostname pcmk02
```

Tắt IPv6 trên cả 2 node

```
vi /etc/sysctl.conf
```

```
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
```

Xem lại cấu hình:

```
sysctl -p
```

Cấu hình SELinux ở chế độ enforcing.

<a name="2.2"></a>
### 2.2 Cài đặt Pacemaker và Corosync

Chạy các lệnh sau trên cả 2 node:

- Cài đặt pcs

```
yum install -y pcs
```

PSC sẽ cài đặt tất cả những gì liên quan tới Pacemaker và Corosync

- Cài gói quản lý SELinux:

```
yum install -y policycoreutils-python
```

- Đặt password cho user của pcs có tên là `hacluster`

```
echo "passwd" | passwd hacluster --stdin
```

**Chú ý**: Thay `'passwd'` bằng mật khẩu của bạn.

<a name="2.3"></a>
### 2.3 Cấu hình Corosync

Bước thực hiện trên node 1

- Xác thực 2 node với nhau thông qua user `hacluster`. Token của quá trình được lưu trữ tại `/var/lib/pcsd/tokens`

```
pcs cluster auth pcmk01-cr pcmk02-cr -u hacluster -p passwd
```

- Tạo file cấu hình và đồng bộ chúng

```
pcs cluster setup --name mysql_cluster pcmk01-cr pcmk02-cr
```

- Khởi động cluster trên tất cả các node

```
pcs cluster start --all
```

<a name="2.4"></a>
### 2.4 Cài đặt DRBD và MariaDB


<a name="2.4.1"></a>
#### 2.4.1 DRBD

Nôm na, DRBD đồng bộ dữ liệu 2 block devices thông qua mạng. Có thể nói đây là cơ chế RAID-1 của các thiết bị logic.

- Chúng ta cài đặt DRBD trên cả 2 node:

```
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
yum install -y kmod-drbd84 drbd84-utils
```

- Cho phép các xử lý của DRBD qua SELinux

```
semanage permissive -a drbd_t
```


<a name="2.4.2"></a>
#### 2.4.2 Tạo LVM Volume cho DRBD

Chúng ta tạo một logic volume trên cả 2 node, như đã nói ở trên thì tùy theo dung lượng DB của các bạn mà tạo dung lượng cho phù hợp. Bài hướng dẫn tôi sẽ demo dung lượng 1GB.

Kiểm tra dung lượng Volume Group

```
vgs
         VG         #PV #LV #SN Attr   VSize  VFree
         vg_centos7   1   3   0 wz--n- 63.21g 45.97g
```

Tạo mới một Logical Volume

```
lvcreate --name lv_drbd --size 1024M vg_centos7
```

<a name="2.4.3"></a>
#### 2.4.3 Cấu hình DRBD

Cấu hình DRBD sử dụng mode `single-primary` với giao thức replication C

- Tạo file cấu hình trên cả 2 node

```
vi /etc/drbd.d/mysql01.res
```

```
resource mysql01 {
 protocol C;
 meta-disk internal;
 device /dev/drbd0;
 disk   /dev/vg_centos7/lv_drbd;
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
 on pcmk01 {
  address  192.168.100.196:7789;
 }
 on pcmk02 {
  address  192.168.100.197:7789;
 }
}
```

Ở đây, chúng ta sẽ có một resource có tên là `mysql01`, nó sử dụng `/dev/vg_centos7/lv_drbd` sử dụng như một lower-level device, được cấu hình với các meta-data.

Nó sử dụng cổng TCP 7789 cho các kết nối mạng ở 2 địa chỉ IP của 2 node. Và hãy mở port này ở firewall.

- Tạo tài nguyên DRBD

```
drbdadm create-md mysql01
```

- Kích hoạt tài nguyên

```
drbdadm up mysql01
```

- Sử dụng tài nguyên trên node 1 (Chỉ chạy lệnh trên node1)

```
drbdadm primary --force mysql01
```

- Tạo filesystem cho DRBD với các tùy chọn sau:

```
mkfs.ext4 -m 0 -L drbd /dev/drbd0
tune2fs -c 30 -i 180d /dev/drbd0
```

- Mount filesystem vừa tạo

```
mount /dev/drbd0 /mnt
```

<a name="2.4.4"></a>
#### 2.4.4 MariaDB

Cài đặt MariaDB trên tất cả các node

```
yum install -y mariadb-server mariadb
```

Không cho khởi động cùng hệ thống, vì tí nữa chúng ta sẽ khai báo tài nguyên và quản lý bởi pacemaker

```
systemctl disable mariadb.service
```

##### Thực hiện trên node 1

Chúng ta khởi động MariaDB để cấu hình cơ bản

```
systemctl start mariadb
```

Khai báo trực tiếp với MariaDB qua câu lệnh

```
mysql_install_db --datadir=/mnt --user=mysql
```

Cấu hình cơ bản MariaDB

```
mysql_secure_installation
```

Khai báo policy vào SELinux về một số tùy chỉnh về thư mục lưu trữ dữ liệu của MariaDB, câu lệnh trên chúng ta đã thay đổi nó về `/mnt` . Mặc định các dữ liệu được lưu trữ tại `/var/lib/mysql`.

```
semanage fcontext -a -t mysqld_db_t "/mnt(/.*)?"
restorecon -Rv /mnt
```

Sau khi hoàn thành các bước trên, chúng ta `umount` filesystem và stop MariaDB.

```
umount /mnt
systemctl stop mariadb
```

Chúng ta sửa file cấu hình trên 2 node với nội dung như sau:

```
vi /etc/my.cnf
```

```
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
```

<a name="2.5"></a>
### 2.5 Cấu hình Pacemaker

Chúng ta sẽ cấu hình cho pacemaker tự động theo logic các dịch vụ như sau:

- Khi Start: mysql_fs01 -> mysql_service01 -> mysql_VIP01
- Khi Stop: mysql_VIP01 -> mysql_service01 -> mysql_fs01

Trong đó:

`mysql_fs01`: là tài nguyên filesystem
`mysql_service01`: là dịch vụ MariaDB
`mysql_VIP01`: là một Virtual IP ở bài viết tôi sử dụng 192.168.100.123

Chúng ta cấu hình trên node thứ nhất của cụm (pcmk01):

Tạo một CIB - lưu trữ và đồng bộ thông tin tài nguyên của các node

```
pcs cluster cib clust_cfg
```

Tắt STONITH và QUORUM:

```
pcs -f clust_cfg property set stonith-enabled=false
pcs -f clust_cfg property set no-quorum-policy=ignore
```

Cấu hình thời để giảm downtime, tăng cường khả năng phục hồi:

```
pcs -f clust_cfg resource defaults resource-stickiness=200
```

Tạo một cụm tài nguyên có tên là `mysql-data01` cho DRDB và tạo một clone chạy đồng thời với nó

```
pcs -f clust_cfg resource create mysql_data01 ocf:linbit:drbd \
drbd_resource=mysql01 \
op monitor interval=30s
```

```
pcs -f clust_cfg resource master MySQLClone01 mysql_data01 \
master-max=1 master-node-max=1 \
clone-max=2 clone-node-max=1 \
notify=true
```

Tạo một cụm cluster tài nguyên có tên là `mysql_fs01` cho filesystem. Và cấu hình cho các tài nguyên cùng chạy trên một node

```
pcs -f clust_cfg resource create mysql_fs01 Filesystem \
device="/dev/drbd0" \
directory="/var/lib/mysql" \
fstype="ext4"

pcs -f clust_cfg constraint colocation add mysql_fs01 with MySQLClone01 \
INFINITY with-rsc-role=Master

pcs -f clust_cfg constraint order promote MySQLClone01 then start mysql_fs01
```

Tương tự, chúng ta cũng tạo một tài nguyên `mysql_service01` cho MariaDB

```
pcs -f clust_cfg resource create mysql_service01 ocf:heartbeat:mysql \
binary="/usr/bin/mysqld_safe" \
config="/etc/my.cnf" \
datadir="/var/lib/mysql" \
pid="/var/lib/mysql/mysql.pid" \
socket="/var/lib/mysql/mysql.sock" \
additional_parameters="--bind-address=0.0.0.0" \
op start timeout=60s \
op stop timeout=60s \
op monitor interval=20s timeout=30s

pcs -f clust_cfg constraint colocation add mysql_service01 with mysql_fs01 INFINITY

pcs -f clust_cfg constraint order mysql_fs01 then mysql_service01
```

Cuối cùng, chúng ta tạo một cụm tài nguyên cho VIP với tên `mysql_VIP01`

```
pcs -f clust_cfg resource create mysql_VIP01 ocf:heartbeat:IPaddr2 \
ip=10.8.8.60 cidr_netmask=32 \
op monitor interval=30s
```

Cấu hình cho chạy trên 1 node và khởi động trước cụm tài nguyên `mysql_service01`

```
pcs -f clust_cfg constraint colocation add mysql_VIP01 with mysql_service01 INFINITY

pcs -f clust_cfg constraint order mysql_service01 then mysql_VIP01
```

Kiểm tra lại những cấu hình

```
pcs -f clust_cfg constraint

Location Constraints:
Ordering Constraints:
  promote MySQLClone01 then start mysql_fs01 (kind:Mandatory)
  start mysql_fs01 then start mysql_service01 (kind:Mandatory)
  start mysql_service01 then start mysql_VIP01 (kind:Mandatory)
Colocation Constraints:
  mysql_fs01 with MySQLClone01 (score:INFINITY) (with-rsc-role:Master)
  mysql_service01 with mysql_fs01 (score:INFINITY)
  mysql_VIP01 with mysql_service01 (score:INFINITY)
```

```
pcs -f clust_cfg resource show

Master/Slave Set: MySQLClone01 [mysql_data01]
     Stopped: [ pcmk01-cr pcmk02-cr ]
 mysql_fs01	(ocf::heartbeat:Filesystem):	Stopped
 mysql_service01	(ocf::heartbeat:mysql):	Stopped
 mysql_VIP01	(ocf::heartbeat:IPaddr2):	Stopped
```

Áp dụng những thay đổi vừa cấu hình

```
pcs cluster cib-push clust_cfg
```

Xem trạng thái:

```
[pcmk01]# pcs status
[...]

Online: [ pcmk01-cr pcmk02-cr ]

Full list of resources:

 Master/Slave Set: MySQLClone01 [mysql_data01]
     Masters: [ pcmk01-cr ]
     Stopped: [ pcmk02-cr ]
 mysql_fs01     (ocf::heartbeat:Filesystem):    Started pcmk01-cr
 mysql_service01        (ocf::heartbeat:mysql): Started pcmk01-cr
 mysql_VIP01    (ocf::heartbeat:IPaddr2):	Started pcmk01-cr

[...]
```


<a name="3"></a>
## 3. Tham khảo

- Nguồn: https://www.lisenet.com/2016/activepassive-mysql-high-availability-pacemaker-cluster-with-drbd-on-centos-7/