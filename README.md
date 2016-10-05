## Ghi chép về các kỹ thuật/giải pháp HA cho mysql/mariadb

###Mục lục:
[1. Giới thiệu về HA cho DB ](#1)

[2. Các giải giải pháp ](#2)

- [2.1 Giải pháp có sẵn ](#2.1)
	
	[2.1.1 Master - Slave ](#2.1.1)	
	
	[2.1.2 Master - Master ](#2.1.2)
	
- [2.2 Giải pháp bên thứ 3 (3rd party) ](#2.2)
	
	[2.2.1 Galera](#2.2.1)
	
	[2.2.2 DRBD ](#2.2.2)
	
	[2.2.3 Radundant Hardware ](#2.2.3)
	
	[2.2.4 Shared Storage ](#2.2.4)
	
	[2.2.5 MySQL clustering  ](#2.2.5)
	
	[2.2.6 Percona cluster  ](#2.2.6)
	
[3. Kết luận ](#3)

<a name="1"></a>
## 1. Giới thiệu về HA

### HA giải quyết được gì?

- Tăng tính hoạt động sẵn sàng dữ liệu mọi lúc mọi nơi
- Nâng cao hiệu suất làm việc của hệ thống
- Nâng cao được tính an toàn dữ liệu
- Đảm bảo hệ thống làm việc không bị gián đoạn

## 2. Các giải pháp

Có 2 giải pháp chính cho việc HA:

- Giải pháp Native: Giải pháp này được mysql/mariadb hỗ trợ.
	- Master - Slave
	- Master - Master

- Giải pháp 3rd party: Cùng với mục đích là để nhất quán dữ liệu với các server với nhau nhưng cơ chế hoạt động và mô hình khác với giải pháp Native. Một số kỹ thuật mà tôi đã tìm hiểu là:
	- Galera
	- DRBD

<a name="2.1"></a>
### 2.1 Giải pháp Native

Cơ chế làm việc như sau: Trên mỗi server sẽ có một user làm nhiệm vụ replication dữ liệu mục đích của việc này là giúp các server đảm bảo tính nhất quán về dữ liệu với nhau.

**Replication** là tính năng cho phép dữ liệu của (các) máy chủ Master được sao chép/nhân bản trên một hoặc nhiều máy chủ khác (Slave). Mục đích của việc này là để sao lưu dữ liệu ra các máy chủ khác đề phòng máy chủ chính gặp sự cố.

<a name="2.1.1"></a>
#### 2.1.1 Master - Slave
**Master - Slave**: là một kiểu trong giải pháp HA cho DB, mục đích để đồng bộ dữ liệu của DB chính (Master) sang một máy chủ DB khác gọi là Slave một cách tự động.

<img src="http://image.prntscr.com/image/0d9a0a557ae14f3e8677aae42816227c.png" />
<a name="2.1.2"></a>
#### 2.1.2 Master - Master

**Master - Master**: Khi cấu hình kiểu này, 2 DB sẽ tự động đồng bộ dữ liệu cho nhau.

<img src="http://image.prntscr.com/image/442577b161be4ec68008eedbfeb3f89d.png" />

## 2.2 Giải pháp 3rd party

<a name="2.2.1"></a>
### 2.2.1 Galera

**Galera Cluster** là giải pháp tăng tính sẵn sàng cho cách Database bằng các phân phối các thay đổi (đọc - ghi dữ liệu) tới các máy chủ trong Cluster. Trong trường hợp một máy chủ bị lỗi thì các máy chủ khác vẫn sẵn sàng hoạt động phục vụ các yêu cầu từ phía người dùng.

<img src="http://image.prntscr.com/image/53203642d97c4866bfdfd52d7e54af33.png" />

Cluster có 2 mode hoạt động là **Active - Passive** và **Active - Active**:

- **Active - Passive**: Tất cả các thao tác ghi sẽ được thực hiện ở máy chủ Active, sau đó sẽ được sao chép sang các máy chủ Passive. Các máy chủ Passive này sẽ sẵn sàng đảm nhiệm vai trò của máy chủ Active khi xảy ra sự cố. Trong một vài trường hợp, **Active - Passive** cho phép `SELECT` ở các máy chủ Passive.
- **Active - Active**: Thao tác đọc - ghi dữ liệu sẽ diễn ra ở mỗi node. Khi có thay đổi, dữ liệu sẽ được đồng bộ tới tất cả các node

Hướng dẫn cài đặt trên:

- [Ubuntu] ()
- [CentOS] ()

<a name="2.2.2"></a>
### 2.2.2 DRBD (Distributed Replicated Block Device)

#### Khái niệm/Định nghĩa

- Phục vụ cho việc sao chép dữ liệu từ một thiết bị này sang thiết bị khác, đảm bảo dữ liệu luôn được đồng nhất giữa 2 thiết bị
- Việc sao chép là liên tục do ánh xạ với nhau ở mức thời gian thực
- Được ví như RAID 1 qua mạng

#### Nhiệm vụ của DRDB trong HA mysql/mariadb

- Khi được cài đặt trên các cụm cluter, DRBD đảm nhiệm việc đồng bộ dữ liệu của các server trong cụm cluters với nhau

#### Kết hợp với heartbeat

- Là một tiện ích chạy ngầm trên máy master để kiểm tra trạng thái hoạt động.  Khi máy master xảy ra sự cố, heartbeat sẽ khởi động các dịch vụ ở máy phụ để phục vụ thay máy master.

<img src="https://bobcares.com/wp-content/uploads/mysql-high-availability-drbd-replication.jpg" />

<a name="2.2.3"></a>
### 2.2.3 Radundant Hardware - Sử dụng tài nguyên phần cứng

Thuật ngữ 'Two of Everything", nghĩa là sử dụng 2 tài nguyên phần cứng cho một máy chủ. Có nghĩa rằng một máy chủ sẽ có 2 nguồn cấp điện, 2 ổ cứng, 2 card mạng,...

<a name="2.2.4"></a>
### 2.2.4 Shared Storage

Để khắc phục lại những sự cố mà server có thể gặp phải, một máy chủ backup được cấu hình nhằm mục đích sao lưu và duy trì các hoạt động khi server chính bị lỗi. Sử dụng NAS hoặc SAN bên trong các server để đồng bộ dữ liệu giữa các máy chủ với nhau.

<img src="https://bobcares.com/wp-content/uploads/mysql-high-availability-shared-storage.jpg" />

<a name="2.2.5"></a>
### 2.2.5 MySQL clustering

Với các Database lớn, clustering làm nhiệm vụ chia nhỏ dữ liệu và phân phối vào các server nằm ở bên trong cụm máy chủ cluster. Trong trường hợp một máy chủ bị lỗi, dữ liệu vẫn được lấy từ các node khác đảm bảo hoạt động của người dùng không bị gián đoạn.

<a name="2.2.6"></a>
### 2.2.6 Percona cluster 

Giống với Galera, Percona có ít nhất 3 node luôn đồng bộ dữ liệu với nhau. Dữ liệu có thể được đọc/ghi lên bất kỳ node nào trong mô hình. Một máy chủ đứng ở bên trên tiếp nhận các truy vấn và phân phối lại một cách đồng đều cho các server bên dưới.

<img src="https://bobcares.com/wp-content/uploads/MySQL-high-availability-Percona-XtraDB.jpg" />

<a name="3"></a>
### 3. Kết luận

Nâng cao khả năng hoạt động cho cơ sở dữ liệu là điều vô cùng quan trọng, nó giúp các ứng dụng sử dụng DB của bạn hoạt động nhịp nhàng, trơn tru hơn. Trên đây là một vài giải pháp nâng cao hiệu năng hoạt động của DB. Dựa vào điều kiện thực tế mà có thể lựa chọn giải pháp phù hợp với mô hình của mình.
