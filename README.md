# 🚀 BÀI LAB THỰC HÀNH: AI IN NETWORKING (DEMO DECK & LAB GUIDE)

> **Dành cho Học viên CCNA / Kỹ sư Mạng**  
> **Mục tiêu:** Thực hành áp dụng AI (ChatGPT, Claude, Gemini) như một **Trợ lý vận hành chuyên nghiệp** để giải quyết 2 bài toán thực tế: **Troubleshooting sự cố mạng** và **Tự động hóa Giám sát hệ thống (Grafana/SNMP)**.

---

## 💻 YÊU CẦU MÔI TRƯỜNG & HƯỚNG DẪN DÀNH CHO LAPTOP WINDOWS

- **Hệ điều hành:** 
  - 🖥️ **Windows (Windows 10/11):** Sử dụng **WSL 2 (Ubuntu 22.04 LTS)** + Docker + Containerlab.  
    👉 **[XEM HƯỚNG DẪN CÀI ĐẶT CHI TIẾT DÀNH CHO HỌC VIÊN WINDOWS](deploy/WINDOWS_STUDENT_GUIDE.md)**
  - 🐧 **Linux (Ubuntu/Debian):** Cài trực tiếp `docker`, `docker-compose`, `containerlab`.
  - 🍎 **macOS:** Chạy Ubuntu trong Virtual Machine (UTM/Parallels/Multipass) để chạy containerlab.

- **Trợ lý AI:** Sử dụng bất kỳ mô hình AI nào (ChatGPT, Claude, Gemini hoặc Ollama local).

---

## 🛠️ DEMO 1: AI-ASSISTED TROUBLESHOOTING (VRRP + OSPF)

### 📌 Tình huống thực tế
Hệ thống mạng LAN công ty (`10.0.10.0/24`) dùng 2 Router gateway `r1` (Priority 200 - Master) và `r2` (Priority 100 - Backup) chạy **VRRP** dự phòng VIP `10.0.10.1`, định tuyến ra backbone qua **OSPF Area 0**.  
Đồng nghiệp báo sự cố:  
> *"Mạng chập chờn liên tục. Kiểm tra thấy CẢ HAI Router đều tự nhận là MASTER (Split-brain)! Khi tắt r1 thì máy trạm hoàn toàn mất kết nối ra internet dù r2 vẫn đang bật."*

---

### 🎯 Mục tiêu học viên
- **KHÔNG đoán mò hay gõ lệnh ngẫu nhiên.**
- Thu thập log/output thực tế ➔ Nạp cho AI theo **Khung Prompt chuẩn 6 bước**.
- Dùng AI làm "Đồng nghiệp Senior" để khoanh vùng giả thuyết và lấy lệnh `show` kiểm chứng.
- Tự gõ lệnh sửa lỗi trên Lab và Verify kịch bản Failover.

---

### 📋 Các bước học viên thực hiện

#### Bước 1: Deploy Bài Lab
```bash
cd demo-1
sudo containerlab deploy -t topology/chaos-vrrp.clab.yml
```

#### Bước 2: Thu thập Dữ liệu Triệu chứng
Chạy các lệnh kiểm tra và copy toàn bộ Output (không mô tả bằng lời):
```bash
# Kiểm tra trạng thái VRRP trên 2 router
docker exec clab-chaos-vrrp-lab-r1 vtysh -c "show ip vrrp"
docker exec clab-chaos-vrrp-lab-r2 vtysh -c "show ip vrrp"

# Kiểm tra kết nối từ Host
docker exec clab-chaos-vrrp-lab-host-a ping -c 4 10.0.12.2
```

#### Bước 3: Đặt Prompt cho AI (Khóa lệnh sửa lỗi)
Copy prompt mẫu sau dán vào AI cùng với Output ở Bước 2:
```text
Bối cảnh: Mạng LAN 10.0.10.0/24 dùng 2 router r1/r2 chạy VRRP (VIP 10.0.10.1), nối backbone qua OSPF area 0 trên FRR.
Triệu chứng: Cả r1 và r2 đều báo trạng thái MASTER. Tắt r1 thì máy trạm mất mạng dù r2 vẫn bật.
Dữ liệu: [Dán Output show ip vrrp ở Bước 2 vào đây]

Yêu cầu:
1. Phân tích dữ liệu và đưa ra 3 giả thuyết khả dĩ nhất từ xác suất cao xuống thấp.
2. Với mỗi giả thuyết, gợi ý ĐÚNG 1 LỆNH show để tôi tự kiểm chứng.
3. RÀNG BUỘC: CHƯA ĐƯA CÂU LỆNH CẤU HÌNH SỬA LỖI.
```

#### Bước 4: Tự Kiểm chứng & Sửa lỗi
AI sẽ gợi ý kiểm tra cấu hình (`show run`). Sau khi thu thập `show run`, bạn sẽ phát hiện 2 lỗi độc lập:
1. **Lỗi 1 (VRRP Split-Brain):** `r2` khai sai VRID (`vrrp 20` thay vì `vrrp 10`) và VIP trùng IP host.  
   ➔ **Sửa trên r2:** Chỉnh lại `vrrp 10` và VIP `10.0.10.1`.
2. **Lỗi 2 (OSPF Routing):** `r2` khai nhầm network `10.0.20.0/24` thay vì `10.0.10.0/24`.  
   ➔ **Sửa trên r2:** Khai báo đúng `network 10.0.10.0/24 area 0`.

#### Bước 5: Kiểm tra lại (Verify Failover)
```bash
# Tắt cổng eth1 của r1 để giả lập sự cố
docker exec clab-chaos-vrrp-lab-r1 ip link set eth1 down

# Kiểm tra r2 tự động chuyển thành Master và host-a vẫn ping thông
docker exec clab-chaos-vrrp-lab-r2 vtysh -c "show ip vrrp"
docker exec clab-chaos-vrrp-lab-host-a ping -c 4 10.0.12.2
```

📄 **Hướng dẫn chi tiết:** Xem file [`demo-1/README.md`](demo-1/README.md) và quy trình troubleshooting tại [`demo-1/AI-TROUBLESHOOTING.md`](demo-1/AI-TROUBLESHOOTING.md).

---

## 📊 DEMO 2: TỰ ĐỘNG HÓA GIÁM SÁT MẠNG (GRAFANA + SNMP + PROMETHEUS)

### 📌 Tình huống thực tế
Leader yêu cầu bạn xây dựng Dashboard giám sát mạng trên Grafana cho Router biên (`edge-gw` có 2 kênh WAN):
1. **Phần cứng (Hardware Resource):** CPU, RAM, Disk.
2. **Trạng thái cổng (Port Status):** Thống kê Port Up/Down.
3. **Băng thông (Traffic Throughput):** Lưu lượng sử dụng realtime trên 2 kênh Internet.

---

### 🎯 Mục tiêu học viên
- Biết cách sử dụng AI dịch các chỉ số SNMP/OID phức tạp sang **cú pháp PromQL chuẩn xác**.
- Sử dụng AI giải thích các OID MIB mạng tiếng Anh sang tiếng Việt dễ hiểu.
- Thực hành thao tác live "Port Down" để thấy Dashboard phản ứng realtime.

---

### 📋 Các bước học viên thực hiện

#### Bước 1: Build Image & Sinh Config Exporter
```bash
# 1. Build image Docker cho Router biên
cd demo-2/images
docker build -t demo2-edge-gw:latest -f edge-gw.Dockerfile .

# 2. Sinh config snmp_exporter
cd ../monitoring/snmp_exporter
./generate.sh
```

#### Bước 2: Deploy Bài Lab & Monitoring Stack
```bash
# 1. Deploy Topology Router biên
cd ../..
sudo containerlab deploy -t topology/network-monitoring.clab.yml

# 2. Start stack Grafana + Prometheus + SNMP Exporter
cd monitoring
docker compose up -d
```

#### Bước 3: Trải nghiệm & Thực hành hỏi AI về PromQL
1. Truy cập Grafana: [http://localhost:3000](http://localhost:3000) (Tài khoản: `admin` / `admin`).
2. Mở Dashboard: **Network Monitoring - Demo 2**.
3. **Hỏi AI để viết PromQL cho Panel Băng thông WAN1:**
   ```text
   Bối cảnh: Prometheus đang thu thập metric SNMP từ snmp_exporter với metric ifHCInOctets (đơn vị Byte).
   Yêu cầu: Viết câu truy vấn PromQL tính tốc độ băng thông chiều Download (đơn vị Bit/s) theo thời gian thực (rút gọn trong 1 phút) cho interface 'eth1'.
   ```
   ➔ **AI trả về PromQL:** `rate(ifHCInOctets{instance="edge-gw", ifDescr="eth1"}[1m]) * 8`

#### Bước 4: Thực hành Kịch bản "Port Down" (Live Failover)
Chạy lệnh đánh sập cổng `eth1` trên Router biên để kiểm tra cảnh báo:
```bash
# Đánh sập cổng eth1
docker exec clab-network-monitoring-lab-edge-gw ip link set eth1 down
```
➔ **Quan sát trên Grafana:** Panel Port eth1 chuyển sang màu ĐỎ, băng thông WAN1 lập tức rơi về `0 bit/s` trong 15 giây.  
 Khôi phục cổng:
```bash
docker exec clab-network-monitoring-lab-edge-gw ip link set eth1 up
```

📄 **Hướng dẫn chi tiết:** Xem file [`demo-2/README.md`](demo-2/README.md).

---

## 🧹 DỌN DẸP MÔI TRƯỜNG SAU KHI THỰC HÀNH

```bash
# Dọn dẹp Demo 1
cd demo-1
sudo containerlab destroy -t topology/chaos-vrrp.clab.yml

# Dọn dẹp Demo 2
cd ../demo-2/monitoring && docker compose down
cd .. && sudo containerlab destroy -t topology/network-monitoring.clab.yml
```

---
*Repo bài lab thuộc bộ chuyên đề thuyết trình: **AI in Networking - Từ cú pháp lệnh đến trợ lý vận hành**.*
