# Ghi chép câu lệnh PING

`PING` (viết tắt của Packet InterNet Groper) là một tiện ích để kiểm tra hoặc xác định có một địa chỉ IP hay một host/server đang hoạt động hay không. Công cụ này thường dùng để kiểm tra và chuẩn đoán lỗi với các vấn đề trong mạng máy tính. Cách hoạt động của nó vô cùng đơn giản là gửi đi một bản tin đến một địa chỉ, host/server nào đó và chờ bản tin phản hồi trả về.

PING là một phương pháp chính để troubleshoot cho bất kỳ các kết nối mạng nào. Nó gửi đi các thông điệp chứa thông tin PING và nhận về các phản hồi từ các host/server. Nó cho ta biết thời gian gói tin được trả về từ các host/server.

Ngày nay, tiện ích này được cài đặt sẵn trên các hệ điều hành máy tính. Trên Windows, bạn có thể dùng Command Prompt. Trên một số hệ điều hành khác như LINUX, MAC OS là Terminal.

**Chú ý**: Một số host hoặc server vì lý do bảo mật mà có thể chặn các gói tin PING.

### Một số thông điệp trả về khi PING:

- Request time out: thực hiện gửi gói thành công nhưng không nhận được gói phản hồi. (Lỗi ở Phía xa)
- Destination host unreachable: đích đến không tồn tại hoặc đang cô lập. (Lỗi ở phía mình)
- Reply from 203.162.4.190 byte=32 time <1ms TTL 124: Gửi gói đến địa chỉ IP: 203.162.4.190 với độ dài gói 32 byte, thời gian phản hồi dưới 1 mili giây, TTL (time to live - vòng đời gói) 124. Phản ánh trạng thái gói gửi và tín hiệu phản hồi. TTL mỗi khi đi qua một ROUTER thì sẽ giảm đi 1 đơn vị và đi qua không quá 30 host. Host sử dụng Windows (Mặc định 128) TTL > 98, Dùng Linux (Mặc định 64) > 34.

### Một số tham số thường dùng

Thực hiện trên Terminal của CentOS 6

#### PING thông thường tới 1 host

```
ping meditech.vn
```

<img src="http://image.prntscr.com/image/9beec10f16a84321947f2476812f4869.png" />

Trên Windows, nếu không có tham số nào đi cùng thì mặc định 4 gói tin được gửi đến host với size là 32 byte.

Khác với Windows, ở LINUX, nếu không có tham số đi cùng thì mặc định số gói tin sẽ không giới hạn với size là 64 byte.
Để ngừng việc ping, chúng ta thao tác [Ctrl] + [C]. Ở Windows, nếu muốn PING không giới hạn thêm tham số `-t`

#### PING với số gói

```
ping -n 8 meditech.vn
```
<img src="http://image.prntscr.com/image/eff6a5bd5e5a48d6a75597dde4b63782.png" />

Thông tin phía dưới cho ta thấy được, tổng số gói tin đã gửi. Bao nhiêu gói tin gửi thành công, và bao nhiêu gói tin gửi lỗi.

Với LINUX, chúng ta thay -n bằng -c.

```
ping -c 8 meditech.vn
```

<img src="http://image.prntscr.com/image/4b7cc2907aae4ef5a2ad559a5709d1ca.png" />

#### PING với tùy chọn kích cỡ gói tin

```
ping -l 1024 meditech.vn
```

<img src="http://image.prntscr.com/image/3ea6013218b44b629f3067238dd387f9.png" />

Giá trị cao nhất của tham số `-l` là 65500, điều này có nghĩa gói tin ping lớn nhất chỉ 65500 bytes (~65,5KB)

#### Tùy chọn thời gian gửi gói tin tiếp theo

```
ping -i 2 meditech.vn
```

<img src="http://image.prntscr.com/image/addee54a217947f494ac4712166cf0a9.png" />

2 giây sẽ gửi gói tin tiếp theo đến host.

#### Gửi gói tin liên tiếp đến host

```
ping -f meditech.vn
```

Với tham số `-f`, ping sẽ gửi liên tiếp các gói tin đến host cho đến khi bạn bấm Ctrl + C.

#### Phân tích kết quả với PING

```
ping -c 5 -q meditech.vn
```

<img src="http://image.prntscr.com/image/c0bd1e3bfafb413b9b776ac08fdbc75b.png" />

Với `-q`, chúng ta chỉ thấy kết quả phân tích mà không thấy gói tin cụ thể được gửi.

#### PING trong khoảng thời gian

```
ping -w 10 meditech.vn
```

<img src="http://image.prntscr.com/image/3288f033403a4803abcbbbc065a53367.png" />

Câu lệnh trên sẽ ping đến host trong khoảng thời gian 10s.
