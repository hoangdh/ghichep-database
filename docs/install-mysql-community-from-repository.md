## Cài đặt thông qua Repository của MySQL Community

### 1. Cài đặt Repository của MySQL

```
yum install -y yum-utils
rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm
```

Trong ví dụ này, ta sẽ cài đặt MySQL bản 5.7. Mặc định, repo của bản 8.0 (mới nhất trong thời điểm viết bài) được kích hoạt. Do vậy, ta sẽ kích hoạt bản 5.7 và tắt bản 8.0.

```
yum-config-manager --disable mysql80-community
yum-config-manager --enable mysql57-community
```

Kiểm tra lại thông tin của gói cài đặt `mysql-community-server`

> yum info mysql-community-server.x86_64

### 2. Cài đặt MySQL

Sau khi kích hoạt, ta sử dụng lệnh sau để cài đặt `mysql-community` bản 5.7

> yum install -y mysql-community-server.x86_64

Chờ khoảng 3-5p, tùy thuộc vào tốc độ mạng và cấu hình máy chủ của bạn.

Khởi động và kích hoạt MySQL

```
systemctl start mysqld
systemctl enable mysqld
```

### 3. Cấu hình MySQL

#### 3.1 Lấy mật khẩu tạm thời của `root`

Từ bản 5.6, mỗi khi cài đặt mới thì mật khẩu của user `root` - quản trị của MySQL được lưu trữ trong log của MySQL tại `/var/log/mysqld.log`

> grep -oP "temporary password(.*): \K(\S+)" /var/log/mysqld.log

#### 3.2 Cấu hình cơ bản MySQL

Sử dụng câu lệnh `mysql_secure_installation` để thay đổi mật khẩu root và xóa bỏ CSDL test, user test,...

Đăng nhập bằng mật khẩu tạm thời và thay đổi mật khẩu với độ bảo mật cao (Bao gồm chữ HOA, chữ thường, số và một số ký tự đặc biệt)

```
# mysql_secure_installation

Securing the MySQL server deployment.

Enter password for user root: 

The existing password for the user account root has expired. Please set a new password.

New password: 

Re-enter new password: 
The 'validate_password' plugin is installed on the server.
The subsequent steps will run with the existing configuration
of the plugin.
Using existing password for root.

Estimated strength of the password: 100 
Change the password for root ? ((Press y|Y for Yes, any other key for No) : n

 ... skipping.
By default, a MySQL installation has an anonymous user,
allowing anyone to log into MySQL without having to have
a user account created for them. This is intended only for
testing, and to make the installation go a bit smoother.
You should remove them before moving into a production
environment.

Remove anonymous users? (Press y|Y for Yes, any other key for No) : y
Success.


Normally, root should only be allowed to connect from
'localhost'. This ensures that someone cannot guess at
the root password from the network.

Disallow root login remotely? (Press y|Y for Yes, any other key for No) : y
Success.

By default, MySQL comes with a database named 'test' that
anyone can access. This is also intended only for testing,
and should be removed before moving into a production
environment.


Remove test database and access to it? (Press y|Y for Yes, any other key for No) : y
 - Dropping test database...
Success.

 - Removing privileges on test database...
Success.

Reloading the privilege tables will ensure that all changes
made so far will take effect immediately.

Reload privilege tables now? (Press y|Y for Yes, any other key for No) : y
Success.

All done! 
```

#### Sử dụng chính sách mật khẩu kém bảo mật

Từ bản 5.6, MySQL mặc định sử dụng chính sách mật khẩu bảo mật ở mức cao, điều này dẫn tới nhiều rắc rối khi một số Tool tự động tạo user MySQL để cài đặt 'khốn đốn'. Để tắt tính năng này, ta sử dụng một trong những cách sau:

- C1: Thêm vào file cấu hình `/etc/my.cnf`

```
[mysqld]
...
validate_password_policy=LOW
...
```

- C2: Sử dụng câu lệnh

> mysql -uroot -p -e "SET GLOBAL validate_password_policy=LOW"
