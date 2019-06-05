## Cấu hình MySQL Replication Master - Slave

- IP Master: 10.10.10.1
- IP Slave: 10.10.10.2

### 1. Cấu hình trên máy chủ Master

Tạm dừng dịch vụ MySQL

> systemctl stop mysqld

Thêm các dòng sau vào file cấu hình `/etc/my.cnf`

```
[mysqld]
bind-address=0.0.0.0
log-bin=/var/lib/mysql/mysql-bin
server-id=101
```

Khởi động dịch vụ MySQL

> systemctl start mysqld

Đăng nhập vào MySQL, tạo một user sử dụng trong quá trình replication

> mysql -uroot -p

```
mysql> grant replication slave on *.* to replica@'10.10.10.2' identified by 'password';

Query OK, 0 rows affected (0.00 sec)
mysql> flush privileges;

```

Khóa bảng và dump dữ liệu <a name='1' />

```
mysql> flush tables with read lock;

Query OK, 0 rows affected (0.00 sec)

mysql> show master status;

+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000001 |      592 |              |                  |                   |
+------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)

```

> **Chú ý**: Ghi nhớ thông tin này để khai báo khi [cấu hình trên Slave](#2)

Mở một cửa sổ terminal khác để dump dữ liệu

> \# mysqldump -u root -p --all-databases --lock-all-tables --events > mysql_dump.sql 

Quá trình dump hoàn thành, quay trở lại terminal trước để Unlock các bảng

```
mysql> unlock tables; 
mysql> exit
```

Chuyển dữ liệu vừa dump sang máy chủ slave.

### 2. Cấu hình máy chủ Slave

Thêm các dòng sau vào file cấu hình `my.cnf` trên máy chủ Slave

```
[mysqld]
...
log-bin=/var/lib/mysql/mysql-bin
# define server ID (different one from Master Host)
server-id=102
# read only
read_only=1
```

Khởi động lại MySQL

> systemctl restart mysqld

Khôi phục lại dữ liệu vừa dump trên Master. Ví dụ, file dump được copy về để ở thư mục /tmp

> mysql -u root -p < /tmp/mysql_dump.sql
<a name='2' />
Sau khi xong, đăng nhập vào MySQL để cấu hình Repilcate Master Slave

> mysql -uroot -p.

```
mysql> change master to
    -> master_host='10.10.10.1',
    -> master_user='replica',
    -> master_password='password',
    -> master_log_file='mysql-bin.000001',
    -> master_log_pos=592;
 mysql> start slave;
 mysql> show slave status\Gd
 ```

**Chú ý**: Điền thông tin log_file và log_pos trùng khớp với thông số mà ta đã lấy ở bước [trên](#1).
