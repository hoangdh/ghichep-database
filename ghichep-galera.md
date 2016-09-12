# Ghi chép cài đặt Galera Cluster

### Menu

[1. Giới thiệu về Galera ](#1)

[2. Chuẩn bị ](#2)

	[2.1 Chuẩn bị ](#2.1)
	
	[2.2 Thiết lập IP cho các node ](#2.2)
	
	[2.3 Mô hình ](#2.3)
	
[3. Các bước tiến hành ](#3)

	[Bước 1. Thêm repo cho các máy chủ ](#3.1)
	
	[Bước 2. Cài đặt MySQL và Galera trên các máy chủ  ](#3.2)
	
	[Bước 3. Cấu hình ở máy chủ thứ nhất ](#3.3)
	
	[Bước 4. Cấu hình trên các node còn lại ](#3.4)
	
	[Bước 5. Cấu hình Firewall trên các máy chủ ](#3.5)
	
	[Bước 6. Khởi động Cluster](#3.6)
	
	[Bước 7. Cấu hình Debian Maintenance User](#3.7)
	
	[Bước 8. Kiểm tra hoạt động  ](#3.8)
	
[4. Kết luận](#4)

<a name="1"></a>
## 1. Giới thiệu Galera

**Galera Cluster** là giải pháp tăng tính sẵn sàng cho cách Database bằng các phân phối các thay đổi (đọc - ghi dữ liệu) tới các máy chủ trong Cluster. Trong trường hợp một máy chủ bị lỗi thì các máy chủ khác vẫn sẵn sàng hoạt động phục vụ các yêu cầu từ phía người dùng.

<img src="http://image.prntscr.com/image/53203642d97c4866bfdfd52d7e54af33.png" />

Cluster có 2 mode hoạt động là **Active - Passive** và **Active - Active**:

- **Active - Passive**: Tất cả các thao tác ghi sẽ được thực hiện ở máy chủ Active, sau đó sẽ được sao chép sang các máy chủ Passive. Các máy chủ Passive này sẽ sẵn sàng đảm nhiệm vai trò của máy chủ Active khi xảy ra sự cố. Trong một vài trường hợp, **Active - Passive** cho phép `SELECT` ở các máy chủ Passive.
- **Active - Active**: Thao tác đọc - ghi dữ liệu sẽ diễn ra ở mỗi node. Khi có thay đổi, dữ liệu sẽ được đồng bộ tới tất cả các node

Bài hướng dẫn dưới đây tôi sẽ cấu hình cho nó hoạt động ở mode **Active - Active**.

<a name="2"></a>
## 2. Chuẩn bị

<a name="2.1"></a>
### 2.1. Môi trường cài đặt

```
root@node3:~# lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 16.04.1 LTS
Release:        16.04
Codename:       xenial
root@node3:~# uname -a
Linux node3.hoang.lab 4.4.0-36-generic #55-Ubuntu SMP Thu Aug 11 18:01:55 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
```

<a name="2.2"></a>
### 2.2. Thiết lập IP cho các node

```
IP:
Node 1: 192.168.100.192
Node 2: 192.168.100.193
Node 3: 192.168.100.194

GATEWAY: 192.168.100.1
```

<a name="2.3"></a>
### 2.3. Mô hình

<img width=75% src="http://image.prntscr.com/image/17b32d1639c447ac92e115524185d123.png" />

<a name="3"></a>
## 3. Các bước tiến hành

<a name="3.1"></a>
### Bước 1: Thêm repo cho các máy chủ

```
apt-key adv --keyserver keyserver.ubuntu.com --recv  44B7345738EBDE52594DAD80D669017EBC19DDBA
add-apt-repository 'deb [arch=amd64,i386] http://releases.galeracluster.com/ubuntu/ xenial main'
apt-get update 
```

<a name="3.2"></a>
### Bước 2: Cài đặt MySQL và Galera trên các máy chủ

```
apt-get install galera-3 galera-arbitrator-3 mysql-wsrep-5.6
apt-get install rsync
```

Trong khi cài đặt mysql có yêu cầu nhập password cho `root` - quản lý MySQL

<img src="http://image.prntscr.com/image/358e882a5f094eb09f705301231252db.png" />

**Note:** `rsync` là thành phần thiết yếu của Galera.

<a name="3.3"></a>
### Bước 3: Cấu hình ở máy chủ thứ nhất

Tạo một file có tên `galera.cnf` trong thư mục `/etc/mysql/conf.d` với nội dung

```
vi /etc/mysql/conf.d/galera.cnf
```

```
[mysqld]
query_cache_size=0
binlog_format=ROW
default-storage-engine=innodb
innodb_autoinc_lock_mode=2
query_cache_type=0
bind-address=0.0.0.0

# Galera Provider Configuration
wsrep_on=ON
wsrep_provider=/usr/lib/galera/libgalera_smm.so

# Galera Cluster Configuration
wsrep_cluster_name="test_cluster"
wsrep_cluster_address="gcomm://first_ip,second_ip,third_ip"

# Galera Synchronization Configuration
wsrep_sst_method=rsync

# Galera Node Configuration
wsrep_node_address="this_node_ip"
wsrep_node_name="this_node_name"
```

Note:

- Điền địa chỉ IP của các máy chủ thay thế `first_ip,second_ip,third_ip`
- Điền địa chỉ IP của node đang cấu hình vào trường `this_node_ip`
- Điền tên của node vào `this_node_name` (Tên tùy chọn, phục vụ cho việc Debug)

<img src="http://image.prntscr.com/image/efc3ed97bf7348ac91b5149a83103449.png" />

**Tiếp theo**, vào file `my.cnf` và comment out lại dòng `bind-address`

```
vi /etc/mysql/my.cnf
```

<img src="http://image.prntscr.com/image/ce3f53cc95d34bbebc4de3dfe9daf7e1.png" />

<a name="3.4"></a>
### Bước 4: Cấu hình trên các node còn lại

Ở các node còn lại, chúng ta copy file `galera.cnf`  ở node thứ nhất vào thư mục `/etc/mysql/conf.d/` của 2 node còn lại. Chỉnh sửa nội dung cho phù hợp với node. Cụ thể

```
. . .
# Galera Node Configuration
wsrep_node_address="this_node_ip"
wsrep_node_name="this_node_name"
. . .
```

Thay thế `this_node_ip` và `this_node_name` ở file `galera.cnf`

Trên node 2:

<img src="http://image.prntscr.com/image/238b7c8331a744da88fa829e877ee4f5.png" />

Trên node 3:

<img src="http://image.prntscr.com/image/06ef8065a2d046a1a51bb6b83d9370e5.png" />

Cũng như ở node 1, trên các node còn lại, chúng ta vào `my.cnf` và comment out dòng `bind-address`

```
vi /etc/mysql/my.cnf
```

Trên node 2:

<img src="http://image.prntscr.com/image/b3cdda5a7aea49409f20668a2e98a8c3.png" />

Trên node 3:

<img src="http://image.prntscr.com/image/06e10f66eeae4c22af80025db14efaf3.png" />

<a name="3.5"></a>
### Bước 5: Cấu hình Firewall trên các máy chủ

`Galera` sử dụng 4 port để làm việc

- `3306`: Cho phép các MySQL-Client kết nối đến server
- `4567`: Cho phép các máy chủ có replication các trafic với nhau và hoạt động ở cả UDP và TCP
- `4568`: For Incremental State Transfer.
- `4444`: For all other State Snapshot Transfer.

```
ufw enable
ufw allow 22,3306,4567,4568,4444/tcp
ufw allow 4567/udp
```

<img src="http://image.prntscr.com/image/6a7d3e8dfaed4313affff30e889aaaa7.png" />

Khi bật Firewall, hệ thống sẽ hỏi có giữ lại phiên SSH hiện tại. Chúng ta chọn `Y` và tiếp tục cấu hình các bước tiếp theo. Câu lệnh `ufw status` có trong hình để xem lại trạng thái của Firewall.

<a name="3.6"></a>
### Bước 6: Khởi động Cluster

#### Stop dịch vụ mysql trên tất cả các node

```
systemctl stop mysql
```

#### Chạy dịch vụ ở node 1

```
/etc/init.d/mysql start --wsrep-new-cluster
```

Kiểm tra bằng câu lệnh

```
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
```

Kết quả hiện ra 

```
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 1     |
+--------------------+-------+
```

<img src="http://image.prntscr.com/image/5bc9923e69b04e7890bb864b68334368.png" />

#### Chạy dịch vụ ở node 2

```
systemctl start mysql
```

Kiểm tra bằng câu lệnh

```
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
```

Kết quả hiện ra 

```
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 2     |
+--------------------+-------+
```

<img src="http://image.prntscr.com/image/d17a3cd2781d413fb81e38473732cbdd.png" />

#### Chạy dịch vụ ở node 3

```
systemctl start mysql
```

Kiểm tra bằng câu lệnh

```
mysql -u root -p -e "SHOW STATUS LIKE 'wsrep_cluster_size'"
```

Kết quả hiện ra 

```
+--------------------+-------+
| Variable_name      | Value |
+--------------------+-------+
| wsrep_cluster_size | 3     |
+--------------------+-------+
```

<img src="http://image.prntscr.com/image/d0e2750174184034beccc834cc3d4301.png" />

<a name="3.7"></a>
### Bước 7: Cấu hình Debian Maintenance User

Hiện tại, trên Ubuntu và Các máy chủ mysql của Debian sẽ có một user đặc biệt để thực hiện các quá trình trong Galera. Mặc định, khi cài đặt sẽ có một user được tạo ra và được ghi ở `/etc/mysql/debian.cnf` trên mỗi server.

#### Copy file từ máy chủ thứ nhất (node 1) ra các máy chủ còn lại

Bước này khá đơn giản, chúng ta copy file `debian.cnf` từ server thứ nhất sang các server khác

Nội dung của file:

```
[client]
host     = localhost
user     = debian-sys-maint
password = 03P8rdlknkXr1upf
socket   = /var/run/mysqld/mysqld.sock
[mysql_upgrade]
host     = localhost
user     = debian-sys-maint
password = 03P8rdlknkXr1upf
socket   = /var/run/mysqld/mysqld.sock
basedir  = /usr
```

Thử đăng nhập vào mysql:

```
mysql -u debian-sys-maint -p
```

<img src="http://image.prntscr.com/image/01a555d17cbb4f44a0158942748477a3.png" />

Nếu không được, hãy đăng nhập vào bằng `root` và chỉnh sửa lại password cho nó.

```
update mysql.user set password=PASSWORD('password_from_debian.cnf') where User='debian-sys-maint';
```

**Note:** Thay thế `password_from_debian.cnf` bằng chuỗi trong password trong file `debian.cnf`

<a name="3.8"></a>
### Bước 8: Test

#### Ghi dữ liệu vào Node 1

```
mysql -u root -p -e 'CREATE DATABASE playground;
CREATE TABLE playground.equipment ( id INT NOT NULL AUTO_INCREMENT, type VARCHAR(50), quant INT, color VARCHAR(25), PRIMARY KEY(id));
INSERT INTO playground.equipment (type, quant, color) VALUES ("slide", 2, "blue");'
```

<img src="http://image.prntscr.com/image/c76db32eade74e9f816ead8a91b0464e.png" />

#### Đọc và ghi dữ liệu vào Node 2

```
mysql -u root -p -e 'SELECT * FROM playground.equipment;'
```

Kết quả:

<img src="http://image.prntscr.com/image/0c11bfa00c7047b1a92aef8501366c68.png" />

Ghi dữ liệu: 

```
mysql -u root -p -e 'INSERT INTO playground.equipment (type, quant, color) VALUES ("swing", 10, "yellow");'
```

<img src="http://image.prntscr.com/image/47c10496cef746b9af883db06499d09b.png" />

#### Đọc và ghi dữ liệu trên Node 3

```
mysql -u root -p -e 'SELECT * FROM playground.equipment;'
```

Kết quả:

<img src="http://image.prntscr.com/image/d3c60c1bce244a5aaaf607f2ad582938.png" />

Ghi dữ liệu

```
mysql -u root -p -e 'INSERT INTO playground.equipment (type, quant, color) VALUES ("seesaw", 3, "green");'
```

<img src="http://image.prntscr.com/image/a65fa2caf1f54a39a112a679253b3ff9.png" />

#### Đọc dữ liệu trên Node 1

```
mysql -u root -p -e 'SELECT * FROM playground.equipment;'
```

Kết quả:

<img src="http://image.prntscr.com/image/7d893aa53ee347758e059fc6c2e2705f.png" />

<a name="4"></a>
## 4. Kết luận

Trên đây là hướng dẫn cấu hình Galera với mô hình hoạt động là **Active - Active** trên hệ điều hành Ubuntu 16.  Hy vọng có thể giúp ích cho hệ thống của các bạn.  Chúc các bạn thành công!