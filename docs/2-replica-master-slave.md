## Cấu hình MySQL Replication Master - Slave

MySQL replication là một tiến trình cho phép sao chép dữ liệu của MySQL một cách tự động từ máy chủ Master sang máy chủ Slave. Nó vô cùng hữu ích cho việc backup dữ liệu hoặc sử dụng để phân tích mà không cần thiết phải truy vấn trực tiếp tới CSDL chính hay đơn giản là để mở rộng mô hình.

Bài lab này sẽ thực hiện với mô hình 2 máy chủ: 1 máy chủ master sẽ gửi thông tin, dữ liệu tới một máy chủ slave khác (Có thể chung hoặc khác hạ tầng mạng). Để thực hiện, trong ví dụ này sử dụng 2 IP:

- IP Master: 10.10.10.1
- IP Slave: 10.10.10.2

### 1. Cấu hình trên máy chủ Master

#### Tạm dừng dịch vụ MySQL

> systemctl stop mysqld

#### Khai báo cấu hình cho Master

Thêm các dòng sau vào file cấu hình `/etc/my.cnf`

```
[mysqld]
...
bind-address=10.10.10.1
log-bin=/var/lib/mysql/mysql-bin
server-id=101
```

- `bind-address`: Cho phép dịch vụ lắng nghe trên IP. Mặc định là 127.0.0.1 - localhost
- `log-bin`: Thư mục chứa log binary của MySQL, dữ liệu mà Slave lấy về thực thi công việc replicate.
- `server-id`: Số định danh Server

#### Khởi động dịch vụ MySQL

> systemctl start mysqld

Đăng nhập vào MySQL, tạo một user sử dụng trong quá trình replication

> mysql -uroot -p

```
mysql> grant replication slave on *.* to replica@'10.10.10.2' identified by 'password';

Query OK, 0 rows affected (0.00 sec)
mysql> flush privileges;

```

Khóa tất cả các bảng và dump dữ liệu <a name='1' />

```
mysql> flush tables with read lock;
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

Thêm các dòng sau vào file cấu hình `my.cnf` trên máy chủ Slave. Mục đích là định danh máy chủ slave và chỉ ra nơi lưu trữ bin-log.

```
[mysqld]
...
log-bin=/var/lib/mysql/mysql-bin
server-id=102
```

Khởi động lại MySQL

> systemctl restart mysqld

Khôi phục lại dữ liệu vừa dump trên Master. Ví dụ, file dump được copy về để ở thư mục /tmp

> mysql -u root -p < /tmp/mysql_dump.sql
<a name='2' />
Sau khi xong, đăng nhập vào MySQL để cấu hình Repilcate Master Slave

> mysql -uroot -p

```
mysql> change master to
    -> master_host='10.10.10.1',
    -> master_user='replica',
    -> master_password='password',
    -> master_log_file='mysql-bin.000001',
    -> master_log_pos=592;
 mysql> start slave;
 mysql> show slave status\G
 ```

**Chú ý**: Điền thông tin `log_file` và `log_pos` trùng khớp với thông số mà ta đã lấy ở bước [trên](#1).


### Bonus

Ghi binlog ở slave để có thể thiết lập slave khác từ Slave; sử dụng trong Mô hình Master-Master:

```
...
log_slave_updates = 1
```

