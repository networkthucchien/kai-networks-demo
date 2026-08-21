# 🚀 BÀI LAB THỰC HÀNH: AI IN NETWORKING (DEMO DECK & LAB GUIDE)

> **Dành cho Học viên CCNA / Kỹ sư Mạng**  
> **Mục tiêu:** Thực hành áp dụng AI (ChatGPT, Claude, Gemini) như một **Trợ lý vận hành chuyên nghiệp** để giải quyết 2 bài toán thực tế: **Troubleshooting sự cố OSPF** và **Tự động hóa Giám sát hệ thống (Grafana/SNMP)**.

---

## 💻 YÊU CẦU MÔI TRƯỜNG & HƯỚNG DẪN DÀNH CHO LAPTOP WINDOWS

- **Hệ điều hành:** 
  - 🖥️ **Windows (Windows 10/11):** Sử dụng **WSL 2 (Ubuntu 22.04 LTS)** + Docker + Containerlab.  
    👉 **[XEM HƯỚNG DẪN CÀI ĐẶT CHI TIẾT DÀNH CHO HỌC VIÊN WINDOWS](WINDOWS_STUDENT_GUIDE.md)**
  - 🐧 **Linux (Ubuntu/Debian):** Cài trực tiếp `docker`, `docker-compose`, `containerlab`.
  - 🍎 **macOS:** Chạy Ubuntu trong Virtual Machine (UTM/Parallels/Multipass) để chạy containerlab.

- **Trợ lý AI:** Sử dụng bất kỳ mô hình AI nào (ChatGPT, Claude, Gemini hoặc Ollama local).

---

## 📄 TÀI LIỆU TRA CỨU NHANH & CHEATSHEET
👉 **[XEM CHEATSHEET & QUY TRÌNH CHUẨN HÓA DATA DÀNH CHO HỌC VIÊN](CHEATSHEET.md)**  
*(Bao gồm: Công cụ Regex ẩn IP/Password, Python script làm sạch config, Khung Prompt 6 bước, Ma trận kiểm soát và Grafana MCP Prompts).*

---

## 🛠️ DEMO 1: AI-ASSISTED TROUBLESHOOTING (OSPF MULTI-AREA)

### 📌 Tình huống thực tế
Hệ thống chạy **OSPF ba area** nối hai site qua backbone: `srv1 — r1 — r2 — r3 — r4 — srv2`.  
Đồng nghiệp báo sự cố **đúng một câu, không thêm thông tin gì khác**:
> *"srv1 không ping được srv2."*

| Đoạn | Subnet | Area theo thiết kế |
| :--- | :--- | :--- |
| srv1 ↔ r1 | `10.1.1.0/24` | 1 |
| r1 ↔ r2 | `10.12.0.0/30` | 1 |
| r2 ↔ r3 | `10.23.0.0/30` | **0 (backbone)** |
| r3 ↔ r4 | `10.34.0.0/30` | 2 |
| r4 ↔ srv2 | `10.4.4.0/24` | 2 |

---

### 🎯 Mục tiêu học viên
- **KHÔNG đoán mò hay gõ lệnh ngẫu nhiên.**
- Thu thập log/output thực tế ➔ Nạp cho AI theo **Khung Prompt chuẩn 6 bước**.
- Dùng AI làm "Đồng nghiệp Senior" để khoanh vùng giả thuyết và lấy lệnh `show` kiểm chứng.
- Tự loại trừ 5 nguyên nhân kinh điển khiến OSPF không lên neighbor, rồi tự gõ lệnh sửa.

---

### 📋 Các bước học viên thực hiện

#### Bước 0: Thí nghiệm 2 phút — cho AI đoán khi CHƯA có dữ liệu
Trước khi thu thập gì cả, hỏi AI đúng một câu:
```text
Mạng OSPF ba area, srv1 không ping được srv2. Nguyên nhân là gì?
```
Quan sát: AI có nói thẳng một nguyên nhân như thể nó biết chắc không? Bao nhiêu ý trong câu trả lời thực sự áp dụng được cho topology mà nó **chưa hề nhìn thấy**?

👉 **Bài học:** AI **mù bối cảnh**. Càng ít dữ liệu, nó càng lấp đầy bằng suy đoán — với giọng văn tự tin y hệt lúc nó đúng.

#### Bước 1: Deploy Bài Lab
```bash
cd demo-1
sudo containerlab deploy -t topology/chaos-ospf.clab.yml
```

#### Bước 2: Thu thập Dữ liệu Triệu chứng
Chạy các lệnh kiểm tra và copy toàn bộ Output (không mô tả bằng lời):
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

#### Bước 3: Đặt Prompt cho AI (Khóa lệnh sửa lỗi)
Copy prompt mẫu sau dán vào AI cùng với Output ở Bước 2:
```text
Bối cảnh: Lab OSPF 3 area trên FRR (vtysh). Topology chuỗi: srv1(10.1.1.10) — r1 — r2 — r3 — r4 — srv2(10.4.4.10).
Thiết kế: srv1↔r1 và r1↔r2 thuộc area 1; r2↔r3 (10.23.0.0/30) là backbone area 0; r3↔r4 và r4↔srv2 thuộc area 2.
Triệu chứng: srv1 không ping được srv2.
Dữ liệu: [Dán output show ip ospf neighbor của 4 router và show ip route ospf ở Bước 2 vào đây]

Yêu cầu:
1. Dựa trên dữ liệu, cho biết adjacency đứt ở chặng nào.
2. Đưa ra 3 giả thuyết khả dĩ nhất từ xác suất cao xuống thấp.
3. Với mỗi giả thuyết, gợi ý ĐÚNG 1 LỆNH show để tôi tự kiểm chứng.
4. RÀNG BUỘC: CHƯA ĐƯA CÂU LỆNH CẤU HÌNH SỬA LỖI. Đánh dấu [CẦN XÁC NHẬN] ở điểm bạn đang giả định.
```

#### Bước 4: Tự Loại trừ Giả thuyết
AI sẽ nêu nhóm nguyên nhân kinh điển làm OSPF không lên neighbor. **Đúng một cái là nguyên nhân thật** — việc của bạn là chạy lệnh loại trừ, không phải tin cái AI xếp đầu bảng:

| # | Giả thuyết | Lệnh loại trừ |
| :--- | :--- | :--- |
| 1 | Area ID hai đầu lệch nhau | `show ip ospf interface <if>` hai đầu, so `Area` |
| 2 | Subnet/netmask hai đầu lệch | `show ip ospf interface <if>`, so `Internet Address` |
| 3 | Hello/Dead timer lệch | `show ip ospf interface <if>`, so `Timer intervals` |
| 4 | Authentication lệch | `show ip ospf`, so `Area has ... authentication` |
| 5 | MTU lệch | `show ip ospf interface <if>`, so `MTU ... bytes` |

💡 **Mẹo đọc dấu hiệu:** neighbor **không xuất hiện chút nào** → lỗi tầng Hello (nhóm 1–4). Neighbor **xuất hiện rồi kẹt** ở `ExStart`/`Exchange` → nghi MTU.

#### Bước 5: Sửa lỗi & Xác nhận đủ 3 tầng
Sau khi xác định được tham số lệch, vào router liên quan sửa qua `vtysh`, rồi verify **cả ba tầng** — đừng dừng ở "ping thông":
```bash
docker exec clab-chaos-ospf-lab-r2 vtysh -c "show ip ospf neighbor"   # 1. adjacency lên Full
docker exec clab-chaos-ospf-lab-r1 vtysh -c "show ip route ospf"      # 2. có route 10.4.4.0/24
docker exec clab-chaos-ospf-lab-srv1 ping -c 4 10.4.4.10              # 3. dữ liệu thật đi được
```

<details>
<summary>⚠️ <b>ĐÁP ÁN — chỉ mở sau khi đã tự troubleshoot hoặc thật sự bí!</b></summary>

**Nguyên nhân:** `r3` khai link backbone sai area — `network 10.23.0.0/30 area 2` trong khi `r2` khai `area 0`.

Area ID nằm **trong gói Hello**. Hai đầu link gửi Hello với Area ID khác nhau (`0.0.0.0` vs `0.0.0.2`) → mỗi bên loại bỏ Hello của bên kia → adjacency **không bao giờ** hình thành. Không adjacency thì không trao đổi LSA, không có route.

Cấu hình sai còn khiến `r3` không có interface nào thuộc area 0 → **area 2 mất kết nối backbone**, vi phạm quy tắc nền tảng "mọi area phải chạm area 0".

**Sửa trên r3:**
```bash
docker exec -it clab-chaos-ospf-lab-r3 vtysh
```
```
conf t
router ospf
  no network 10.23.0.0/30 area 2
  network 10.23.0.0/30 area 0
end
write
```

</details>

📄 **Hướng dẫn chi tiết:** Xem file [`demo-1/README.md`](demo-1/README.md) (kèm bảng ánh xạ cú pháp **FRR ↔ Cisco IOS**) và quy trình troubleshooting tại [`demo-1/AI-TROUBLESHOOTING.md`](demo-1/AI-TROUBLESHOOTING.md).

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
sudo containerlab destroy -t topology/chaos-ospf.clab.yml

# Dọn dẹp Demo 2
cd ../demo-2/monitoring && docker compose down
cd .. && sudo containerlab destroy -t topology/network-monitoring.clab.yml
```

---
*Repo bài lab thuộc bộ chuyên đề thuyết trình: **AI in Networking - Từ cú pháp lệnh đến trợ lý vận hành**.*
