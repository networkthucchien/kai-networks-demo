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
│  │      ├─ demo-1: OSPF Multi-Area (r1 → r4)        │  │
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

### ⏱️ Bước 3: LÀM TRƯỚC BUỔI HỌC — Tải sẵn Docker Image

> **Bắt buộc làm ở nhà, đừng để tới hội trường.** Wifi hội trường tải image có thể ăn hết thời lượng demo.

```bash
docker pull quay.io/frrouting/frr:10.5.1
docker pull wbitt/network-multitool:3.22.2
```

Kiểm tra đã có đủ:
```bash
docker images | grep -E "frr|multitool"
```

---

## 🚀 PHẦN 2: THỰC HÀNH LAB DEMO 1 (TROUBLESHOOTING OSPF MULTI-AREA)

### Bước 1: Clone Repo về máy trong WSL2
Trong cửa sổ Ubuntu WSL2:
```bash
git clone https://github.com/thangpa/kai-networks-demo.git
cd kai-networks-demo/demo-1
```

### Bước 2: Deploy Bài Lab Demo 1
```bash
sudo containerlab deploy -t topology/chaos-ospf.clab.yml
```

Topology: `srv1 — r1 — r2 — r3 — r4 — srv2`, chạy OSPF 3 area. Thiết kế: `srv1↔r1` và `r1↔r2` thuộc **area 1**; `r2↔r3` (`10.23.0.0/30`) là **backbone area 0**; `r3↔r4` và `r4↔srv2` thuộc **area 2**.

### Bước 3: Xác nhận Triệu chứng & Thu thập Log nạp cho AI
Đồng nghiệp chỉ báo đúng một câu: *"srv1 không ping được srv2."*

```bash
# Triệu chứng gốc
docker exec clab-chaos-ospf-lab-srv1 ping -c 4 10.4.4.10

# Trạng thái adjacency toàn mạng
docker exec clab-chaos-ospf-lab-r1 vtysh -c "show ip ospf neighbor"
docker exec clab-chaos-ospf-lab-r2 vtysh -c "show ip ospf neighbor"
docker exec clab-chaos-ospf-lab-r3 vtysh -c "show ip ospf neighbor"
docker exec clab-chaos-ospf-lab-r4 vtysh -c "show ip ospf neighbor"

# Route học được ở hai đầu
docker exec clab-chaos-ospf-lab-r1 vtysh -c "show ip route ospf"
docker exec clab-chaos-ospf-lab-r4 vtysh -c "show ip route ospf"
```

Copy toàn bộ nội dung xuất ra màn hình dán vào AI.

### Bước 4: Đặt Prompt cho AI để nhận gợi ý chẩn đoán
```text
Bối cảnh: Lab OSPF 3 area trên FRR (vtysh). Topology chuỗi: srv1(10.1.1.10) — r1 — r2 — r3 — r4 — srv2(10.4.4.10).
Thiết kế: srv1↔r1 và r1↔r2 thuộc area 1; r2↔r3 (10.23.0.0/30) là backbone area 0; r3↔r4 và r4↔srv2 thuộc area 2.
Triệu chứng: srv1 không ping được srv2.
Dữ liệu: [Dán output show ip ospf neighbor của 4 router và show ip route ospf vào đây]

Yêu cầu:
1. Dựa trên dữ liệu, cho biết adjacency đứt ở chặng nào.
2. Liệt kê 3 giả thuyết nguyên nhân từ xác suất cao xuống thấp.
3. Với mỗi giả thuyết, gợi ý ĐÚNG 1 LỆNH show để tôi tự kiểm chứng loại trừ.
4. RÀNG BUỘC: CHƯA ĐƯA CÂU LỆNH CẤU HÌNH SỬA LỖI. Đánh dấu [CẦN XÁC NHẬN] ở điểm bạn đang giả định.
```

### Bước 5: Tự chạy lệnh loại trừ giả thuyết
AI sẽ nêu nhóm nguyên nhân kinh điển làm OSPF không lên neighbor. **Đúng một cái là nguyên nhân thật** — tự chạy lệnh loại trừ, đừng tin ngay cái AI xếp đầu bảng:

| # | Giả thuyết | Lệnh loại trừ |
| :--- | :--- | :--- |
| 1 | Area ID hai đầu lệch nhau | `show ip ospf interface <if>` hai đầu, so `Area` |
| 2 | Subnet/netmask hai đầu lệch | `show ip ospf interface <if>`, so `Internet Address` |
| 3 | Hello/Dead timer lệch | `show ip ospf interface <if>`, so `Timer intervals` |
| 4 | Authentication lệch | `show ip ospf`, so `Area has ... authentication` |
| 5 | MTU lệch | `show ip ospf interface <if>`, so `MTU ... bytes` |

Ví dụ so sánh hai đầu link nghi ngờ:
```bash
docker exec clab-chaos-ospf-lab-r2 vtysh -c "show ip ospf interface eth2"
docker exec clab-chaos-ospf-lab-r3 vtysh -c "show ip ospf interface eth1"
```

💡 **Mẹo:** neighbor **không xuất hiện chút nào** → lỗi tầng Hello (nhóm 1–4). Neighbor **xuất hiện rồi kẹt** ở `ExStart`/`Exchange` → nghi MTU.

### Bước 6: Sửa lỗi & Xác nhận đủ 3 tầng
Sau khi tự xác định được tham số lệch, vào CLI router liên quan để sửa:
```bash
docker exec -it clab-chaos-ospf-lab-r3 vtysh
```

<details>
<summary>⚠️ <b>ĐÁP ÁN — chỉ mở sau khi đã tự làm Bước 5 hoặc thật sự bí!</b></summary>

**Nguyên nhân:** `r3` khai link backbone sai area (`area 2` thay vì `area 0`). Area ID nằm trong gói Hello — hai đầu lệch nhau thì adjacency không bao giờ hình thành.

```vtysh
conf t
router ospf
  no network 10.23.0.0/30 area 2
  network 10.23.0.0/30 area 0
end
write
exit
```

</details>

Verify **cả ba tầng** — đừng dừng ở "ping thông":
```bash
docker exec clab-chaos-ospf-lab-r2 vtysh -c "show ip ospf neighbor"   # 1. adjacency lên Full
docker exec clab-chaos-ospf-lab-r1 vtysh -c "show ip route ospf"      # 2. có route 10.4.4.0/24
docker exec clab-chaos-ospf-lab-srv1 ping -c 4 10.4.4.10              # 3. dữ liệu thật đi được
```

### Bước 7: Dọn dẹp bài lab
```bash
sudo containerlab destroy -t topology/chaos-ospf.clab.yml
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

## 🗺️ PHỤ LỤC: ÁNH XẠ CÚ PHÁP FRR ↔ CISCO IOS

Lab chạy trên FRR (`vtysh`). Cú pháp gần trùng Cisco IOS — khác biệt lớn nhất là FRR khai **prefix**, Cisco khai **wildcard mask**. Khái niệm giống hệt nhau.

| Việc cần làm | FRR (`vtysh`) | Cisco IOS |
| :--- | :--- | :--- |
| Khai network vào area | `network 10.23.0.0/30 area 0` | `network 10.23.0.0 0.0.0.3 area 0` |
| Gỡ một khai báo network | `no network 10.23.0.0/30 area 2` | `no network 10.23.0.0 0.0.0.3 area 2` |
| Xem neighbor | `show ip ospf neighbor` | `show ip ospf neighbor` |
| Xem area / timer của interface | `show ip ospf interface eth1` | `show ip ospf interface Gi0/1` |
| Xem route học qua OSPF | `show ip route ospf` | `show ip route ospf` |
| Xem cấu hình đang chạy | `show run` | `show running-config` |
| Lưu cấu hình | `write` | `write memory` |

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
