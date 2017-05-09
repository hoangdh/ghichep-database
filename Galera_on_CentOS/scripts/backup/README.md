## Hướng dẫn sử dụng

[1. Giới thiệu ](#1)

[2. Yêu cầu](#2)

[3. Các bước thực hiện](#3)

<a name="1"></a>
### 1. Giới thiệu

Script này sẽ giúp các bạn cài đặt và cấu hình tự động Galera 3 node cho MariaDB trên CentOS 7. Các bạn có thể xem bài hướng dẫn cài đặt bằng tay ở <a href="https://github.com/hoangdh/ghichep-database/tree/master/Galera_on_CentOS" >đây</a> để hiểu rõ hơn quá trình làm việc của script.

<a name="2"></a>
### 2. Yêu cầu:

- Trên các node phải triển khai SSH-Key (Không có passphare)
- Các SSH-Key phải được đặt tên theo node. Key của node thứ nhất có tên là `node1`, key của node thứ hai có tên là `node2` và key của node thứ 3 là `node3`.
- Các file cấu hình `conf.cfg`, script `galera.bash` và SSH-Key của các node phải nằm trong cùng một thư mục.
- Khi cài đặt và cấu hình, script sẽ không đặt mật khẩu tài khoản `root` trên bất cứ host nào, mặc định password trống. Vì vậy hãy thay đổi nó ngay sau khi quá trình cài đặt thành công.

*Script có thể chạy trên một máy bất kỳ hoặc trên 1 trong 3 node đáp ứng đủ các yêu cầu trên..*

<a name="3"></a>
### 3. Các bước thực hiện

- **Bước 1**: Khai báo thông tin các node của bạn vào file `conf.cfg` theo mẫu:

    ```
    export IP1=192.168.100.196
    export IP2=192.168.100.197
    export IP3=192.168.100.198
    ```
    
    **Chú thích**:
    - `IP1` là địa chỉ IP của node 1
    - `IP2` là địa chỉ IP của node 2
    - `IP3` là địa chỉ IP của node 3
    
- **Bước 2**: Kiểm tra lại các file cấu hình `var.cfg`, script `galera.bash` và SSH-Key của các node trong thư mục

- **Bước 3**: Phân quyền chạy cho script
    
    ```
    chmod 755 galera.bash
    ```
- **Bước 4**: Chạy script

    ```
    ./galera.bash
    ```
    
*Chúc các bạn thành công!*