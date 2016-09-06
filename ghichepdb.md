## Ghi chép thô

### Các giải pháp HA cho DB

#### Giải pháp Native (Thuần túy không sử dụng sản phẩm của bên thứ 3)
- **Master - Slave**: là một kiểu trong giải pháp HA cho DB, mục đích để đồng bộ dữ liệu của DB chính (Master) sang một máy chủ DB khác gọi là Slave một cách tự động.
- **Master - Master**: Khi cấu hình kiểu này, 2 DB sẽ tự động đồng bộ dữ liệu cho nhau. (Cách hiểu nôm na của em là 2 thằng này sẽ là slave của nhau.)

Để thực hiện được kỹ thuật trên, chúng ta cần phải có 2 máy chủ DB. Một máy làm master, máy còn lại làm slave.

#### Giải pháp khác
- **Galera**
- DRBD (Distributed Replicated Block Device)

Nguồn: https://mariadb.com/services/mariadb-mysql-consulting/mariadb-high-availability

#### Replication trong DB

Nguồn: https://mariadb.com/kb/en/mariadb/replication-overview/

**Replication** là tính năng cho phép dữ liệu của (các) máy chủ Master được sao chép/nhân bản trên một hoặc nhiều máy chủ khác (Slave)

**Có thể sao chép/nhân bản được những gì?**

Tùy vào mục đích sử dụng, tính năng này cho phép chúng ta sao chép/nhân bản từ Tất cả các DB trên Master, một hoặc nhiều DB, cho đến các bảng trong mỗi DB sang Slave một cách tự động.

**Cơ chế hoạt động**

Master sẽ gửi các binary-log đến Slave, slave sẽ đọc các binary-log từ master để yêu cầu truy cập dữ liệu vào quá trình replication. Một relay-log được tạo ra trên slave, nó sử dụng có định dạng giống với binary-log. Các relay-log sẽ được sử dụng để replication và relay-log sẽ được xóa bỏ khi hoàn tất quá trình replication.

Các tệp tin binlog sử dụng lần cuối được giữ lại. Khi các máy chủ Slave kết nối lại hoặc tiếp tục replication khi bị gián đoạn.

Các master và slave không nhất thiết phải luôn kết nối với nhau. Nó có thể được đưa về trạng thái offline và khi được kết nối lại, quá trình replication sẽ được tiếp tục ở nơi nó offline.

**Binary-log là gì?**

Binary-log chứa những bản ghi ghi lại những thay đổi của các database. Nó chứa dữ liệu và cấu trúc của DB (có bao nhiêu bảng, bảng có bao nhiêu trường,...), các câu lệnh được thực hiện trong bao lâu,... Nó bao gồm các file nhị phân và các index.

Binary-log được lưu trữ ở dạng nhị phân không phải là dạng văn bản plain-text.

