# 🖥️ HƯỚNG DẪN DEPLOY VÀ THỰC HÀNH CHO HỌC VIÊN DÙNG LAPTOP WINDOWS

> **Dành cho Học viên dùng máy tính chạy Windows 10 / Windows 11**  
> **Phương pháp:** Sử dụng **WSL 2 (Windows Subsystem for Linux 2)** kết hợp với **Docker & Containerlab**. Đây là giải pháp nhẹ nhất, nhanh nhất và mượt mà nhất trên Windows mà không cần cài VirtualBox/VMware nặng nề.

---

## 🏗️ TỔNG QUAN KIẾN TRÚC MÔI TRƯỜNG TRÊN WINDOWS

```
┌────────────────────────────────────────────────────────┐
│ WINDOWS LAPTOP (Windows 10 / 11)                       │
│  │                                                     │
│  ├─ Browser (Chrome/Edge): Truy cập http://localhost:3000  │
│  └─ Terminal (PowerShell / Windows Terminal)           │
│       │                                                │
│       ▼                                                │
│  ┌──────────────────────────────────────────────────┐  │
│  │ WSL 2 (Ubuntu 22.04 LTS)                         │  │
│  │  │                                               │  │
│  │  ├─ Docker Engine                                │  │
│  │  └─ Containerlab (Tạo Network Namespace ảo)      │  │
│  │      ├─ demo-1: FRR Router (VRRP/OSPF)           │  │
│  │      └─ demo-2: edge-gw + Grafana + Prometheus   │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

---

## 🛠️ PHẦN 1: CHUẨN BỊ MÔI TRƯỜNG (CÀI 1 LẦN DUY NHẤT)

### Bước 1: Cài đặt WSL 2 & Ubuntu từ Windows Terminal
1. Tìm **PowerShell** hoặc **Command Prompt** trên Windows ➔ Click chuột phải chọn **Run as Administrator**.
2. Gõ câu lệnh sau:
   ```powershell
   wsl --install -d Ubuntu
   ```
3. Khi lệnh chạy xong, **khởi động lại máy tính (Restart)** nếu Windows yêu cầu.
4. Sau khi khởi động lại, cửa sổ Ubuntu sẽ tự động mở lên.
   - Đặt **Username** (ví dụ: `student`).
   - Đặt **Password** (nhập mật khẩu cá nhân, lưu ý khi gõ mật khẩu sẽ không hiện ký tự).

5. Cập nhật hệ thống trong cửa sổ Ubuntu:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

---

### Bước 2: Cài đặt Docker & Containerlab trong Ubuntu WSL2

Trong cửa sổ Ubuntu WSL2, chạy các lệnh sau:

```bash
# 1. Cài đặt Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 2. Thêm user hiện tại vào nhóm docker (để không cần gõ sudo khi chạy docker)
sudo usermod -aG docker $USER
newgrp docker

# 3. Bật dịch vụ Docker
sudo service docker start

# 4. Cài đặt Containerlab
curl -sL https://containerlab.dev/setup | sudo bash
```

**Kiểm tra xem các công cụ đã sẵn sàng chưa:**
```bash
docker --version
containerlab version
```
*(Nếu hiện ra phiên bản của Docker và Containerlab là cài đặt thành công!)*

---

## 🚀 PHẦN 2: THỰC HÀNH LAB DEMO 1 (TROUBLESHOOTING VRRP + OSPF)

### Bước 1: Clone Repo về máy trong WSL2
Trong cửa sổ Ubuntu WSL2:
```bash
git clone https://github.com/thangpa/kai-networks-demo.git
cd kai-networks-demo/demo-1
```

### Bước 2: Deploy Bài Lab Demo 1
```bash
sudo containerlab deploy -t topology/chaos-vrrp.clab.yml
```

### Bước 3: Thu thập Log nạp cho AI (ChatGPT/Claude/Gemini)
Chạy 2 lệnh sau và copy toàn bộ nội dung xuất ra màn hình dán vào AI:
```bash
docker exec clab-chaos-vrrp-lab-r1 vtysh -c "show ip vrrp"
docker exec clab-chaos-vrrp-lab-r2 vtysh -c "show ip vrrp"
```

### Bước 4: Đặt Prompt cho AI để nhận gợi ý chẩn đoán
```text
Bối cảnh: Mạng LAN 10.0.10.0/24 dùng 2 router r1/r2 chạy VRRP (VIP 10.0.10.1), nối backbone qua OSPF area 0 trên FRR.
Triệu chứng: Cả r1 và r2 đều báo trạng thái MASTER (Split-brain). Tắt r1 thì máy trạm mất mạng dù r2 vẫn bật.
Dữ liệu: [Dán kết quả 2 lệnh show ip vrrp vào đây]

Yêu cầu:
1. Phân tích dữ liệu và liệt kê 3 giả thuyết nguyên nhân từ xác suất cao xuống thấp.
2. Với mỗi giả thuyết, gợi ý ĐÚNG 1 LỆNH show để tôi tự kiểm chứng loại trừ.
3. RÀNG BUỘC: CHƯA ĐƯA CÂU LỆNH CẤU HÌNH SỬA LỖI.
```

### Bước 5: Thực hành gõ lệnh sửa lỗi trên Router r2
Vào môi trường CLI của Router r2:
```bash
docker exec -it clab-chaos-vrrp-lab-r2 vtysh
```
Gõ các câu lệnh sửa (đã xác minh qua AI):
```vtysh
conf t
interface eth1
  no vrrp 20
  vrrp 10
  vrrp 10 ip 10.0.10.1
  vrrp 10 priority 100
exit
router ospf
  no network 10.0.20.0/24 area 0
  network 10.0.10.0/24 area 0
end
write
exit
```

### Bước 6: Dọn dẹp bài lab
```bash
sudo containerlab destroy -t topology/chaos-vrrp.clab.yml
```

---

## 📊 PHẦN 3: THỰC HÀNH LAB DEMO 2 (GRAFANA + SNMP + PROMETHEUS)

### Bước 1: Build Image Docker & Sinh Cấu hình Exporter
Trong cửa sổ Ubuntu WSL2:
```bash
cd ~/kai-networks-demo/demo-2/images
docker build -t demo2-edge-gw:latest -f edge-gw.Dockerfile .

cd ../monitoring/snmp_exporter
./generate.sh
```

### Bước 2: Deploy Lab & Khởi chạy Grafana Monitoring Stack
```bash
cd ../..
sudo containerlab deploy -t topology/network-monitoring.clab.yml

cd monitoring
docker compose up -d
```

### Bước 3: Truy cập Grafana từ Trình duyệt Windows! 🌐
1. Mở trình duyệt Web trên Windows (Google Chrome / Microsoft Edge / Brave...).
2. Đăng nhập địa chỉ: **`http://localhost:3000`**
3. Thông tin đăng nhập:
   - **Username:** `admin`
   - **Password:** `admin`
4. Vào menu **Dashboards** ➔ Chọn **Network Monitoring - Demo 2**.

### Bước 4: Thực hành kịch bản Live "Port Down"
Quay lại cửa sổ Ubuntu WSL2 và chạy lệnh đánh sập cổng `eth1`:
```bash
docker exec clab-network-monitoring-lab-edge-gw ip link set eth1 down
```
➔ **Nhìn màn hình Grafana trên Windows:** Thấy ngay Panel Cổng eth1 chuyển đỏ và Băng thông WAN1 tụt về `0 bit/s`.

Khôi phục lại cổng:
```bash
docker exec clab-network-monitoring-lab-edge-gw ip link set eth1 up
```

### Bước 5: Dọn dẹp bài lab
```bash
cd ~/kai-networks-demo/demo-2/monitoring && docker compose down
cd ~/kai-networks-demo/demo-2 && sudo containerlab destroy -t topology/network-monitoring.clab.yml
```

---

## ❓ CÁC LỖI THƯỜNG GẶP TRÊN WINDOWS & CÁCH XỬ LÝ (FAQ)

### 1. Lỗi: `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`
- **Nguyên nhân:** Dịch vụ Docker trong Ubuntu chưa được khởi chạy.
- **Cách xử lý:** Trong Ubuntu WSL2, gõ lệnh:
  ```bash
  sudo service docker start
  ```

### 2. Lỗi: Trình duyệt Windows không mở được `http://localhost:3000`
- **Nguyên nhân:** Port forwarding giữa WSL2 và Windows bị vướng Firewall hoặc khác IP.
- **Cách xử lý:**
  1. Lấy địa chỉ IP của WSL2 bằng lệnh:
     ```bash
     ip addr show eth0 | grep inet
     ```
  2. Mở trình duyệt trên Windows truy cập bằng IP đó: `http://<IP_WSL2>:3000` (Ví dụ: `http://172.25.16.2:3000`).

### 3. Máy Windows bị đơ / ngốn nhiều RAM khi chạy Docker
- **Cách xử lý:** Giới hạn tài nguyên RAM cho WSL 2:
  1. Trên Windows, mở Notepad và tạo file tại đường dẫn: `C:\Users\<Tên_Windows_Của_Bạn>\.wslconfig`
  2. Dán nội dung sau vào file:
     ```ini
     [wsl2]
     memory=4GB
     processors=2
     ```
  3. Mở PowerShell gõ `wsl --shutdown` rồi mở lại Ubuntu.

---
*Chúc các bạn học viên thực hành lab thành công trên Laptop Windows!*
