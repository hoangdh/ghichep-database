# Backup MySQL lên Minio sử dụng xbstream và xbcloud

## 1. Chuẩn bị

- Percona Toolkit
- MinIO

###  Khai báo thông tin MinIO S3 cho xbcloud

Thêm các thông tin MinIO tương ứng vào file `~/.my.cnf`

> vim ~/.my.cnf

```
...

[xbcloud]
storage=s3
s3-endpoint=http://localhost:9000/
s3-access-key=minio
s3-secret-key=minio123
s3-bucket=backupsx
s3-bucket-lookup=path
s3-api-version=4
```

## 2. Các bước thực hiện

### 2.1 Quá trình sao lưu (Backup)

```
THREADS=10
CHUNKSIZE=200M
HOST="$(hostname)-$(date -I)"

xtrabackup --backup --stream=xbstream --parallel=$THREADS --read-buffer-size=$CHUNKSIZE --extra-lsndir=/data/tmp --target-dir=/data/tmp | xbcloud put --parallel=$THREADS $HOST
```

- Trong đó:
  - `THREADS`: Số luồng xtrabackup chạy
  - `CHUNKSIZE`: Xác định kích thước của object trên MinIO, mặc định: 10MB.
  - `HOST`: Tên thư mục được lưu trên MinIO,. Ví dụ: `mysql1-2022-04-27`
  - **Chú ý:** Có thể thêm các tùy chọn vào lệnh `xtrabackup`. Ví dụ: `--slave-info`: Nếu thực hiện trên máy chủ Slave; ...
  
### 2.2 Quá trình phục hồi (Restore)

Quá trình này cần 2 bước thực hiện là lấy dữ liệu từ S3 MinIO và `apply-log`

#### Lấy dữ liệu từ MinIO

```
THREADS=10
HOST=mysql1-2022-04-27
mkdir -p /data/restore-mysql/$HOST

 xbcloud get -parallel=$THREADS s3://backupsx/$HOST  | xbstream -x -C --parallel=$THREADS /data/restore-mysql/$HOST
```

- Trong đó:
  - `backupsx`: Tên bucket
  - `HOST`:  Tên thư mục sao lưu trên MinIO ở bước trên.

#### Quá trình Apply-log

```
xtrabackup --prepare --use-memory=1G --apply-log-only --target-dir=/data/restore-mysql/$HOST
```

## 3. Tham khảo

- https://docs.percona.com/percona-xtrabackup/2.4/xbcloud/xbcloud.html
