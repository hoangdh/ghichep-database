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

<img src="http://image.prntscr.com/image/9a740938930d4670bd0687a268b4f7f9.png" />
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

<a name="2.2,2"></a>
### 2.2.2 DRBD (Distributed Replicated Block Device)