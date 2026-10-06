# Báo Cáo Thực Hành: Cấu Hình Tường Lửa UFW Và Chuẩn Đoán Cổng Mạng

## 1. Mục Tiêu Bài Tập
1. Sử dụng công cụ tường lửa **UFW (Uncomplicated Firewall)** để bảo vệ máy chủ hệ điều hành Linux.
2. Thiết lập quy tắc chặn/mở cổng mạng theo nguyên lý **Least Privilege** phục vụ việc deploy ứng dụng một cách an toàn.
3. Hiểu và sử dụng thành thạo các công cụ chẩn đoán mạng phổ biến trong DevOps: `ufw status verbose`, `ss -tlnp`, `curl`.

---

## 2. Bối Cảnh & Yêu Cầu Kỹ Thuật

### 2.1. Bối cảnh
Chuẩn bị triển khai một ứng dụng web lắng nghe tại cổng `8080` trên máy chủ Cloud VPS. Để phòng ngừa các cuộc tấn công quét cổng, xâm nhập trái phép và bảo vệ an toàn cho hệ thống, máy chủ cần được cấu hình tường lửa chỉ mở đúng những cổng dịch vụ thực sự cần thiết.

### 2.2. Ràng buộc kỹ thuật
- **Chính sách mặc định (Default Policy):**
  - Chặn toàn bộ kết nối đi vào: `deny incoming`.
  - Cho phép toàn bộ kết nối đi ra: `allow outgoing`.
- **Mở cổng kết nối quản trị:** Mở cổng `22/tcp` (SSH) để đảm bảo không bị ngắt hoặc mất kết nối quản trị từ xa.
- **Mở cổng kết nối ứng dụng:** Mở cổng `8080/tcp` để cho phép truy cập dịch vụ Web từ bên ngoài.
- **Kích hoạt UFW:** Bật tường lửa và xác nhận trạng thái hoạt động `active`.

---

## 3. Các Lệnh Cấu Hình Thực Hiện

### 3.1. Thiết lập chính sách mặc định
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```
- `default deny incoming`: Tự động chặn toàn bộ các gói tin đi vào hệ thống nếu không có luật cho phép cụ thể.
- `default allow outgoing`: Cho phép máy chủ tự do gửi yêu cầu ra ngoài Internet (tải gói cập nhật, giao tiếp với API bên ngoài, v.v.).

### 3.2. Mở cổng SSH và cổng ứng dụng Web
```bash
sudo ufw allow 22/tcp
sudo ufw allow 8080/tcp
```
- `allow 22/tcp`: Cho phép kết nối giao thức TCP đến cổng 22 (SSH).
- `allow 8080/tcp`: Cho phép kết nối giao thức TCP đến cổng 8080 (Web Application).

### 3.3. Kích hoạt tường lửa UFW
```bash
sudo ufw enable
```
*(Hệ thống sẽ hiển thị cảnh báo về việc kết nối SSH hiện tại có thể bị gián đoạn, nhập `y` để xác nhận kích hoạt).*

---

## 4. Kết Quả Kiểm Tra Thực Tế (Verification Output)

### 4.1. Xem trạng thái chi tiết của tường lửa UFW (`sudo ufw status verbose`)
```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere                  
8080/tcp                   ALLOW IN    Anywhere                  
22/tcp (v6)                ALLOW IN    Anywhere (v6)             
8080/tcp (v6)              ALLOW IN    Anywhere (v6)             
```

**Nhận xét kết quả:**
- Trạng thái `Status: active` xác nhận tường lửa đang hoạt động và được nạp tự động khi khởi động hệ thống.
- `Default: deny (incoming), allow (outgoing)` xác nhận chính sách gốc đã được áp dụng chuẩn xác.
- Danh sách quy tắc hiển thị rõ hai cổng `22/tcp` và `8080/tcp` ở trạng thái `ALLOW IN` từ `Anywhere` cho cả IPv4 và IPv6.

---

### 4.2. Kiểm tra các cổng đang lắng nghe trên máy chủ (`ss -tlnp`)
Khi dịch vụ SSH và ứng dụng Web cổng 8080 đang hoạt động:
```text
State  Recv-Q Send-Q  Local Address:Port Peer Address:Port Process                                                
LISTEN 0      4096          0.0.0.0:22        0.0.0.0:*    users:(("sshd",pid=2463,fd=3))
LISTEN 0      5             0.0.0.0:8080      0.0.0.0:*    users:(("python3",pid=4725,fd=3))                     
LISTEN 0      4096             [::]:22           [::]:*    users:(("sshd",pid=2463,fd=4))
```

**Nhận xét kết quả:**
- Cổng `22` đang được tiến trình `sshd` lắng nghe trên tất cả các địa chỉ (`0.0.0.0:22` và `[::]:22`).
- Cổng `8080` đang được tiến trình ứng dụng Web (`python3`) lắng nghe trên `0.0.0.0:8080`.

---

### 4.3. Kiểm tra kết nối dịch vụ ứng dụng Web bằng `curl`
```text
$ curl -I http://127.0.0.1:8080

HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.14.4
Date: Tue, 06 Oct 2026 08:33:41 GMT
Content-type: text/html; charset=utf-8
Content-Length: 336
```
Kết quả trả về mã phản hồi `HTTP 200 OK`, minh chứng dịch vụ phản hồi kết nối bình thường và lưu lượng đi qua cổng 8080 thông suốt.

---

## 5. Phân Tích Kỹ Thuật Chuyên Sâu (DevOps Best Practices)

### 5.1. Tại sao phải mở cổng 22 TRƯỚC KHI kích hoạt UFW?
Khi quản trị máy chủ từ xa (Cloud VPS, AWS EC2, DigitalOcean droplet,...), phiên làm việc được duy trì qua giao thức SSH trên cổng 22. Nếu thiết lập chính sách mặc định là `deny incoming` rồi bật tường lửa ngay mà chưa tạo luật cho phép cổng 22, hệ thống tường lửa sẽ chặn toàn bộ các gói tin SSH mới. Khi đó người quản trị sẽ bị khóa hoàn toàn khỏi máy chủ (*locked out*) và không thể truy cập từ xa để khắc phục nếu không có quyền can thiệp qua giao diện Console vật lý của nhà cung cấp Cloud.

### 5.2. Sự khác biệt giữa `ss -tlnp` và `ufw status`
- **`ufw status`:** Kiểm tra tầng **Packet Filtering (Tường lửa mạng)**. Cho biết những cổng mạng nào được phép đi qua "cửa kiểm soát" của hệ điều hành. Tuy nhiên, việc một cổng được mở trên UFW không đồng nghĩa với việc có dịch vụ đang lắng nghe ở đó.
- **`ss -tlnp`:** Kiểm tra tầng **Socket / Process (Tiến trình dịch vụ)**. Liệt kê các tiến trình thực tế đang bind và listen trên socket mạng tại máy chủ.
- **Quy tắc phối hợp:** Một ứng dụng muốn nhận được kết nối từ người dùng Internet thì bắt buộc phải thỏa mãn đồng thời cả 2 điều kiện:
  1. Ứng dụng phải đang chạy và lắng nghe trên cổng đó (`ss -tlnp` hiển thị `LISTEN`).
  2. Tường lửa mạng phải cho phép kết nối đi vào cổng đó (`ufw status` hiển thị `ALLOW IN`).

---

## 6. Cấu Trúc Mã Nguồn

```text
homework/session_06/ex3/
├── setup.sh     # Script tự động cài đặt, cấu hình default policy và mở các port quy định
├── test.sh      # Script tự động kiểm tra trạng thái ufw, socket ss và thử nghiệm curl
└── README.md    # Báo cáo kết quả và tài liệu kỹ thuật
```
*(Lưu ý: Tuân thủ quy định không chèn comment trong mã nguồn các tệp script shell).*
