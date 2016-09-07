## Ghi chép về các kỹ thuật/giải pháp HA cho mysql/mariadb

###Mục lục:
[1. Giới thiệu về HA cho DB ](#1)

[2. Giải pháp hỗ trợ sẵn ](#2)

- [2.1 Giới thiệu về Replication ](#2.1)
	
- [2.2 Các kiểu Replication ](#2.2)
	
	[2.2.1 Master - Slave ](#2.2.2)	
	
	[2.2.2 Master - Master ](#2.2.2)
		
[3. Giải pháp ngoài ](#3)

- [3.1 Galera](#3.1)
- [3.2 DRBD ](#3.2)

[4. Kết luận ](#4)

<a name="1"></a>
### 1. Giới thiệu

Ngày nay, công nghệ thông tin đã ăn sâu vào nhiều lĩnh vực trong đời sống phục vụ cho sản xuất, giải trí và đặc biệt nhu cầu thông tin. Các hệ thống này luôn được đầu tư với quy mô càng ngày càng mở rộng, là hướng phát triển trọng tâm của doanh nghiệp cung cấp nội dung. Để đảm bảo các dịch vụ chạy thông suốt, phục vụ tối đa đến nhu cầu của người sử dụng và nâng cao tính bảo mật, an toàn dữ liệu; giải pháp High Availability được nghiên cứu và phát triển bởi nhiều hãng công nghệ lớn. Với Database, tính an toàn và khả dụng được đặt lên hàng đầu. Vì vậy, ở bài viết này, chúng tôi xin phép điểm qua một vài Giải pháp HA cho hệ cơ sở dữ liệu sử dụng MySQL hoặc MariaDB đang được cộng đồng tin dùng.

<a name="2"></a>
### 2. Giải pháp hỗ trợ sẵn (Thuần túy không sử dụng sản phẩm của bên thứ 3)

<a name="2.1"></a>
#### 2.1 Giới thiệu về Replication

**Replication** là tính năng cho phép dữ liệu của (các) máy chủ Master được sao chép/nhân bản trên một hoặc nhiều máy chủ khác (Slave). Mục đích của việc này là để sao lưu dữ liệu ra các máy chủ khác đề phòng máy chủ chính gặp sự cố.

**Có thể sao chép/nhân bản được những gì?**

Tùy vào mục đích sử dụng, tính năng này cho phép chúng ta sao chép/nhân bản từ Tất cả các DB trên Master, một hoặc nhiều DB, cho đến các bảng trong mỗi DB sang Slave một cách tự động.

**Cơ chế hoạt động**

Máy chủ Master sẽ gửi các binary-log đến máy chủ Slave. Máy chủ Slave sẽ đọc các binary-log từ Mster để yêu cầu truy cập dữ liệu vào quá trình replication. Một relay-log được tạo ra trên slave, nó sử dụng định dạng giống với binary-log. Các relay-log sẽ được sử dụng để replication và được xóa bỏ khi hoàn tất quá trình replication.

Các master và slave không nhất thiết phải luôn kết nối với nhau. Nó có thể được đưa về trạng thái offline và khi được kết nối lại, quá trình replication sẽ được tiếp tục ở thời điểm nó offline.

**Binary-log là gì?**

Binary-log chứa những bản ghi ghi lại những thay đổi của các database. Nó chứa dữ liệu và cấu trúc của DB (có bao nhiêu bảng, bảng có bao nhiêu trường,...), các câu lệnh được thực hiện trong bao lâu,... Nó bao gồm các file nhị phân và các index.

Binary-log được lưu trữ ở dạng nhị phân không phải là dạng văn bản plain-text.

<a name="2.2"></a>
#### 2.2 Các kiểu Replication

<a name="2.2.1"></a>
##### 2.2.1 Master - Slave
**Master - Slave**: là một kiểu trong giải pháp HA cho DB, mục đích để đồng bộ dữ liệu của DB chính (Master) sang một máy chủ DB khác gọi là Slave một cách tự động.

<img src="http://image.prntscr.com/image/9a740938930d4670bd0687a268b4f7f9.png" />
<a name="2.2.2"></a>
###### 2.2.2 Master - Master

**Master - Master**: Khi cấu hình kiểu này, 2 DB sẽ tự động đồng bộ dữ liệu cho nhau.

<img src="http://image.prntscr.com/image/442577b161be4ec68008eedbfeb3f89d.png" />

<a name="3"></a>
#### 3 Giải pháp ngoài

<a name="3.1"></a>
##### 3.1 Galera

**Galera Cluster** là giải pháp tăng tính sẵn sàng cho cách Database bằng các phân phối các thay đổi (đọc - ghi dữ liệu) tới các máy chủ trong Cluster. Trong trường hợp một máy chủ bị lỗi thì các máy chủ khác vẫn sẵn sàng hoạt động phục vụ các yêu cầu từ phía người dùng.

<img src="http://image.prntscr.com/image/53203642d97c4866bfdfd52d7e54af33.png" />

Cluster có 2 mode hoạt động là **Active - Passive** và **Active - Active**:

- **Active - Passive**: Tất cả các thao tác ghi sẽ được thực hiện ở máy chủ Active, sau đó sẽ được sao chép sang các máy chủ Passive. Các máy chủ Passive này sẽ sẵn sàng đảm nhiệm vai trò của máy chủ Active khi xảy ra sự cố. Trong một vài trường hợp, **Active - Passive** cho phép `SELECT` ở các máy chủ Passive.
- **Active - Active**: Thao tác đọc - ghi dữ liệu sẽ diễn ra ở mỗi node. Khi có thay đổi, dữ liệu sẽ được đồng bộ tới tất cả các node

<a name="3.2"></a>
##### 3.2 DRBD (Distributed Replicated Block Device)


Nguồn: https://mariadb.com/kb/en/mariadb/replication-overview/



