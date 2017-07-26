## Hướng dẫn sử dụng

### Yêu cầu và chuẩn bị:

- Tải 2 file `galera-3-node.sh` và `var.cfg` về một máy bất kỳ và có thể kết nối tới 3 node muốn cài đặt Cluster
- Đảm bảo giữa 3 node phải kết nối được với nhau
- Trên 3 node muốn cài Galera, phải đặt IP tĩnh
- Khai báo lần lượt địa chỉ IP của các máy chủ vào file `var.cfg`
- Khai báo hostname của từng hostname của các máy chủ
- Khai báo password cho user root của MariaDB (User này có quyền truy cập trên tất cả các host)

### Các bước thực hiện:

- Tải script và file chứa các biến về máy:

```
wget 
wget
```

- Chỉnh sửa file `var.cfg` phù hợp với các thông số của bạn

	- `IP1` - `IP3`: Địa chỉ IP của các node mà bạn muốn cài đặt
	- `HOST1` - `HOST3`: Tên hostname của các node cài đặt (Tùy chọn)
	- `PASSWORD`: Mật khẩu của user `root` trong MariaDB.
	
- Phân quyền
	
```
chown +x 
```

- Tiến hành cài đặt - Chạy Script

```
./
```

http://linoxide.com/cluster/mariadb-centos-7-galera-cluster-haproxy/
- chckconfig
- tat selinux

Sử dụng Script như sau:

- Sửa file cấu hình `var.cfg` (Địa chỉ IP, HOSTNAME, password cho user root của MySQL)
- Tạo key SSH (Yêu cầu phải nhập password `root` từng host)
- Tự động cài đặt Galera

*Chúc các bạn thành công!*