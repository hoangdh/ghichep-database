## Hướng dẫn cài đặt Galera cho MariaDB trên CentOS 7

#### Menu

[1. Chuẩn bị ](#1)

- [1.1. Môi trường cài đặt](#1.1)
- [1.2. Thiết lập IP cho các node](#1.2)
- [1.3. Mô hình](#1.3)

[2. Các bước tiến hành](#2)

- [2.1 Cài đặt MariaDB trên các node](#2.1)
- [2.2 Cài đặt Galera cho MariaDB](#2.2)
- [2.3 Kiểm tra hoạt động](#2.3)

[3. Tham khảo](#3)

<a name="1"></a>
## 1. Chuẩn bị

<a name="1.1"></a>
### 1.1. Môi trường cài đặt

```
[root@node1 ~]# cat /etc/redhat-release
CentOS Linux release 7.2.1511 (Core)
[root@node1 ~]# uname -a
Linux node1.hoang.lab 3.10.0-327.28.3.el7.x86_64 #1 SMP Thu Aug 18 19:05:49 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
```

<a name="1.2"></a>
### 1.2. Thiết lập IP cho các node

```
IP:
Node 1: 192.168.100.196
Node 2: 192.168.100.197
Node 3: 192.168.100.198

GATEWAY: 192.168.100.1
NETWORK: 192.168.100.0/24
```

<a name="1.3"></a>
### 1.3. Mô hình

<img width=75% src="http://i1363.photobucket.com/albums/r714/HoangLove9z/1-cluster_zpsxnmbgwiu.png" />

<a name="2"></a>
## 2. Các bước tiến hành

<a name="2.1"></a>
### 2.1. Cài đặt MariaDB trên các node

#### Cài đặt Repo cho các node và set độ ưu tiên của repo

```
yum -y install centos-release-scl-rh centos-release-scl
sed -i -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/CentOS-SCLo-scl.repo
sed -i -e "s/\]$/\]\npriority=10/g" /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo 
```

##### Cài đặt MariaDB

- Cài đặt MariaDB với `yum`

```
yum --enablerepo=centos-sclo-rh -y install rh-mariadb101-mariadb-server 
```

- Load các biến môi trường

```
scl enable rh-mariadb101 bash
```

- Kiểm tra phiên bản của MariaDB

```
mysql -V 
```

<img src="http://image.prntscr.com/image/ae36e8df17b546c481050aad186ec27c.png" />

- Cho `rh-mariadb` khởi động cùng hệ thống, soạn file với nội dung:

```
vi /etc/profile.d/rh-mariadb101.sh 
```

```
#!/bin/bash

source /opt/rh/rh-mariadb101/enable
export X_SCLS="`scl enable rh-mariadb101 'echo $X_SCLS'`"
```

##### Bật MariaDB và cấu hình ban đầu:

- Khai báo thêm bộ mã hóa ký tự UTF-8 vào file cấu hình

```
vi /etc/opt/rh/rh-mariadb101/my.cnf.d/mariadb-server.cnf
```

- Tìm section `[mysqld]` và thêm vào với nội dung

```
...
character-set-server=utf8
...
```

##### Khởi động và cấu hình

- Bật `MariaDB` và cho khởi động cùng hệ thống:

```
systemctl start rh-mariadb101-mariadb
systemctl enable rh-mariadb101-mariadb 
```

- Cài đặt cơ bản

```
mysql_secure_installation 
```

<img src="http://image.prntscr.com/image/97e7126a0d2c428ba44bab3754c4b2d2.png" />

- Cài đặt tiếp theo

<img src="http://i1363.photobucket.com/albums/r714/HoangLove9z/demo_zpsb6xegnv5.png" />

- Kiểm tra Đăng nhập `MariaDB`

```
mysql -uroot -p -e "show databases;"
```

<img src="http://image.prntscr.com/image/cd55528542c44760bd952674e65b4e69.png" />

<a name="2.2"></a>
#### 2.2 Cài đặt Galera cho MariaDB

##### Cài đặt `Galera` trên các node

```
yum --enablerepo=centos-sclo-rh -y install rh-mariadb101-mariadb-server-galera
```

- Cấu hình tường lửa trên các node

```
firewall-cmd --add-service=mysql --permanent
firewall-cmd --add-port={3306/tcp,4567/tcp,4568/tcp,4444/tcp} --permanent
firewall-cmd --reload 
```

- Cấu hình ở Node 1:

```
mv /etc/opt/rh/rh-mariadb101/my.cnf.d/galera.cnf /etc/opt/rh/rh-mariadb101/my.cnf.d/galera.cnf.org 
vi /etc/opt/rh/rh-mariadb101/my.cnf.d/mariadb-server.cnf 
```

- Mở file `mariadb-server.cnf`, tìm đến section `galera` và **chỉnh sửa những dòng** như sau:

```
[galera]
# Mandatory settings
wsrep_on=ON
wsrep_provider=/opt/rh/rh-mariadb101/root/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address=gcomm://

binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Them moi 3 dong nay
wsrep_cluster_name="MariaDB_Cluster"
wsrep_node_address="192.168.100.196"
wsrep_sst_method=rsync
```

<img src="http://image.prntscr.com/image/5517d3701a89412ab6f13c57e6342f5a.png" />

- Sau khi chỉnh sửa xong, khởi động `Galera`

```
/opt/rh/rh-mariadb101/root/usr/bin/galera_new_cluster 
```

- Cấu hình ở các node còn lại:

```
mv /etc/opt/rh/rh-mariadb101/my.cnf.d/galera.cnf /etc/opt/rh/rh-mariadb101/my.cnf.d/galera.cnf.org 
vi /etc/opt/rh/rh-mariadb101/my.cnf.d/mariadb-server.cnf 
```

Mở file `mariadb-server.cnf`, tìm đến section `galera` và **chỉnh sửa những dòng** tương ứng:

```
[galera]
# Mandatory settings
wsrep_on=ON
wsrep_provider=/opt/rh/rh-mariadb101/root/usr/lib64/galera/libgalera_smm.so
wsrep_cluster_address="gcomm://192.168.100.196,192.168.100.197,192.168.100.198"

binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
bind-address=0.0.0.0

# Them moi nhung dong sau:
wsrep_cluster_name="MariaDB_Cluster"
wsrep_node_address="IP_Của_Node_Tương_Ứng"
wsrep_sst_method=rsync
```

#### Trên node 2:

<img src="http://image.prntscr.com/image/20721807c5c14964b7c7b2569fcfa0a3.png" />

#### Trên node 3:

<img src="http://image.prntscr.com/image/05574c5920194b1a986c5bdc612fb932.png" />

- Khởi động lại `MariaDB` trên từng node:

```
systemctl restart rh-mariadb101-mariadb
```

<a name="2.3"></a>
#### 2.3 Kiểm tra hoạt động

- Tạo một database ở node 1:

```
mysql -uroot -p -e "create database node1;"
mysql -uroot -p -e "show databases;"
```

<img src="http://image.prntscr.com/image/3b57ce5034ab4d3a896804f79e85cf58.png" />

- Xem và tạo database ở node 2:

```
mysql -uroot -p

show databases;
create database node2;
```

<img src="http://image.prntscr.com/image/e7085303a51e4218bf7da12b70270013.png" />

- Xem và tạo database ở node 3:

```
mysql -uroot -p

show databases;
create database node3;
```

<img src="http://image.prntscr.com/image/aefac42a78874b43a45bf2d17957ea3d.png" />

- Quay lại node 1, chúng ta kiểm tra lại sẽ có 3 database được tạo:

```
mysql -uroot -p -e "show databases;"
```

<img src="http://image.prntscr.com/image/7bae6d27b1ae44bbb78d9572d5fd23ee.png" />

<a name="3"></a>
3. Tham khảo:

- https://www.server-world.info/en/note?os=CentOS_7&p=mariadb101&f=4