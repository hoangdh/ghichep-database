### Khái niệm GTID

GTID (Global Transaction Identifiers) được giới thiệu từ bản MySQL 5.6, 
- Là một mã định danh duy nhất khi một transaction được commmited trên máy chủ gốc (hay còn gọi là Master). 
- Mã định danh này tồn tại duy nhất trên toàn bộ các máy chủ MySQL (Bao gồm Master và các slave). 
- Giúp việc cấu hình Replicate đơn giản, dễ dàng; đảm bảo tính nhất quán và tin cậy.

GTID bao gồm 2 phần: 
- ServerID: ID của Server, duy nhất theo dạng UUID. Được ghi vào file auto.conf khi khởi tạo MySQL; trong thư mục lưu trữ dữ liệu của MySQL. 
- TransactionID: Là ID của transaction; bắt đầu từ 1 và tăng dần theo thứ tự transaction. 

Ví dụ: `cef98fa3-5396-4ee0-85bb-cb1413d1531b:2135`

### Tính năng của GITD

**Điểm khác nhau giữa GTID-based và log-based**

- Với Log-based, Máy chủ Slave kêt nối tới Master sẽ phải khai báo file binlog và position.
- Với GTID-based: 
  - Trước hết, Slave sẽ gửi thông tin các GTID của các transaction đã được thực thi trên nó cho Master. Sau đó, Master sẽ gửi lại tất cả những transaction chưa được thực thi về Slave; Slave sẽ thực thi các transacction này. Và đảm bảo rằng chỉ thực hiện duy nhất một lần để đảm báo tính nhất quán dữ liệu.
  - Không cần sử dụng `MASTER_LOG_FILE` và `MASTER_LOG_POS`, chỉ cần khai báo `MASTER_AUTO_POSTION=1`
  - Khi sử dụng GITD, bắt buộc các máy chủ Slave cũng phải bật GITD
- Tất cả các Slave phải ghi log; `log_slave_updates=1`

### Cách hoạt động
- Khi một transaction được thực thi trên Master, một GTID được sinh ra, gắn tương ứng vào transaction rồi được ghi vào Binlog.
- Binglog được Slave láy về lưu vào relay-log; Slave đọc GITD và gán giá trị vào biến `GTID_NEXT` để biết được GTID tiếp theo sẽ thực thi. 
- Tiến trình SQL thread trên Slave lấy giá trị GITD từ relay-log và so sánh với binlog. Nếu đã tồn tại, Slave sẽ bỏ qua. Nếu chưa, Slave sẽ thực thi và ghi chúng lại vào binlog của mình.

### Ưu điểm:

- Cấu hình nhanh
- Rút ngắn thời gian thao tác chuyển đổi dự phòng (Failover)
- Tối ưu hơn với binlog là ROW

### Nhược điểm:

- Khó trong việc xử lý khi lỗi xảy ra trên Slave (Không hỗ trợ slave_skip_counter, tuy nhiên có thao tác tương đương - bỏ qua transaction lỗi)
- Không sử dụng được với MyISAM
- Không hỗ trợ tạo bảng create table .. select; và bảng tạm (temporary)
