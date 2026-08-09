# Demo 2: Thực hành Giám sát Mạng bằng Grafana MCP (Model Context Protocol)

## 🎯 Mục tiêu bài lab

Học viên trực tiếp sử dụng **AI Agent thông qua Grafana MCP** để:
1. Kết nối vào Grafana Server chung của lớp học bằng **Service Account Token** được cấp.
2. Tự tạo **1 Thư mục (Folder) cá nhân** trên Grafana.
3. Ra lệnh cho AI **tự động khởi tạo & thiết kế Dashboard giám sát hệ thống mạng** nằm gọn trong Folder cá nhân của mình.

---

## 🔑 Dữ liệu cấp cho Học viên trong buổi học

Giảng viên sẽ cung cấp 2 thông số tại hội trường:
* 🌐 **Grafana URL:** `https://demo-2.9ping.cloud`
* 🔑 **Grafana Service Account Token:** `glsa_KxKcudBy8sB7eAL3VRnZnwXBoleEknYW_00000000` (Ví dụ Token học viên)

---

## 🛠️ HƯỚNG DẪN CẤU HÌNH GRAFANA MCP (CHO HỌC VIÊN)

Học viên cấu hình Grafana MCP Server vào công cụ AI của mình (VS Code, Cursor, Antigravity, Claude Desktop...):

### Cấu hình file `mcpServers` (JSON format):

```json
{
  "mcpServers": {
    "grafana": {
      "command": "npx",
      "args": ["-y", "@grafana/mcp-server"],
      "env": {
        "GRAFANA_URL": "https://demo-2.9ping.cloud",
        "GRAFANA_SERVICE_ACCOUNT_TOKEN": "glsa_KxKcudBy8sB7eAL3VRnZnwXBoleEknYW_00000000"
      }
    }
  }
}
```

> **Lưu ý:** Thay thế `GRAFANA_URL` và `GRAFANA_SERVICE_ACCOUNT_TOKEN` bằng đúng thông số giảng viên cấp tại chỗ.

---

## 📋 THỰC HÀNH TỪNG BƯỚC (STEP-BY-STEP HANDS-ON)

### 📁 Bước 1: Tạo Folder cá nhân trên Grafana
Mở khung Chat AI và gõ Prompt:

```text
Dùng Grafana MCP tool, hãy tạo cho tôi 1 Folder mới trên Grafana có tên là "HV_NguyenVanA_Dashboard" (thay tên bạn vào đây).
```

👉 **Kết quả kỳ vọng:** AI gọi tool `create_folder` (hoặc tương đương) của Grafana MCP và thông báo Folder đã tạo thành công kèm Folder UID/URL.

---

### 📊 Bước 2: Ra lệnh cho AI tạo Dashboard giám sát mạng
Gõ tiếp Prompt để AI tự sinh Dashboard:

```text
Hãy dùng Grafana MCP để tạo một Dashboard mới tên là "Network Monitoring System" nằm bên trong folder "HV_NguyenVanA_Dashboard" vừa tạo.

Dashboard cần bao gồm các panel giám sát sau:
1. Panel CPU/RAM/Disk của router biên (edge-gw).
2. Panel Trạng thái các Port mạng (Up/Down).
3. Panel Băng thông Traffic kênh Internet WAN1 (Interface eth1) và WAN2 (Interface eth2).
```

👉 **Kết quả kỳ vọng:** AI sẽ tự động soạn cấu hình JSON Dashboard ( PromQL queries, panel types, layout) và dùng MCP tool đẩy thẳng lên Grafana Server.

---

### 🔍 Bước 3: Nghiệm thu & Tinh chỉnh trên Grafana Web UI

1. Mở trình duyệt truy cập: [https://demo-2.9ping.cloud](https://demo-2.9ping.cloud)
2. Tìm đến thư mục cá nhân của bạn (VD: `HV_NguyenVanA_Dashboard`).
3. Mở Dashboard **Network Monitoring System** vừa được AI tạo tự động.
4. Thử ra lệnh cho AI tinh chỉnh tiếp nếu muốn (VD: *"Đổi màu panel WAN1 sang xanh neon và chỉnh thời gian refresh thành 5s"*).

---

## 🧪 KỊCH BẢN GIẢ LẬP SỰ CỐ "PORT DOWN" (LIVE DEMO)

Để kiểm tra Dashboard có cập nhật thực tế hay không, giảng viên / học viên có thể hạ cổng mạng trên Router lab:

```bash
# Hạ cổng WAN1 (eth1) trên router edge-gw
docker exec clab-network-monitoring-lab-edge-gw ip link set eth1 down
```

→ **Hiện tượng:** Panel Port Status chuyển sang **Đỏ (Down)** và Băng thông WAN1 tụt về **0 Mbps** trên Grafana sau 15 giây (chu kỳ scrape).

Khôi phục lại cổng:
```bash
docker exec clab-network-monitoring-lab-edge-gw ip link set eth1 up
```

---

## 🏗️ DÀNH CHO GIẢNG VIÊN (DỰNG HẠ TẦNG LAB DEMO 2)

<details>
<summary>⚠️ Bấm để xem hướng dẫn dựng Stack Prometheus + Grafana cho Server Lab</summary>

### 1. Build image edge-gw
```bash
cd demo-2/images
docker build -t demo2-edge-gw:latest -f edge-gw.Dockerfile .
```

### 2. Deploy Topology & Monitoring Stack
```bash
cd demo-2
sudo containerlab deploy -t topology/network-monitoring.clab.yml

cd demo-2/monitoring
./snmp_exporter/generate.sh
docker compose up -d
```

### 3. Cấp Service Account Token trên Grafana
* Đăng nhập Grafana (admin/admin).
* Vào **Administration** → **Users & access** → **Service accounts**.
* Tạo Service Account mới (Role: `Admin` hoặc `Editor`) → **Add token** → Copy Token phát cho học viên.

</details>

