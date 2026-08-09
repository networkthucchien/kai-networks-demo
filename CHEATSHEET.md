# 🛠️ AI IN NETWORKING: CHEATSHEET & DATA SANITIZATION GUIDE

> **Bộ tài liệu tra cứu nhanh (Cheat Sheet) dành cho Học viên CCNA / Kỹ sư Mạng**  
> Bao gồm: **Công cụ chuẩn hóa Data**, **Đoạn Regex làm sạch Log/Config**, **Khung Prompt chuẩn 6 bước**, **Ma trận Kiểm soát AI** và **Grafana MCP Prompts**.

---

## 🔐 1. QUY TRÌNH CHUẨN HÓA & LÀM SẠCH DỮ LIỆU (DATA SANITIZATION)

### ⚠️ Tại sao phải làm sạch dữ liệu trước khi gửi cho AI?
* **Không đưa dữ liệu nhạy cảm của công ty/doanh nghiệp** (IP thật, mật khẩu mã hóa/plain-text, SNMP community string, VPN keys, Certificate) lên AI công cộng.
* **Nguyên tắc "Human-in-the-Loop":** Kỹ sư mạng chịu trách nhiệm về dữ liệu gửi đi và lệnh dán vào sản xuất.

### 📋 Checklist 5 điểm cần Sanitized/Anonymized
1. **Public IP / Private IP thật:** Đổi thành IP mẫu RFC 1918 (`10.X.X.X`, `192.168.1.X`, `172.16.X.X` hoặc `100.64.X.X`).
2. **Password / Secret / Hash:** Đổi thành `[REDACTED_PASSWORD]` hoặc `<PASSWORD>`.
3. **SNMP Community string:** Đổi thành `public` hoặc `[REDACTED_COMMUNITY]`.
4. **Tên thiết bị / Hostname / Domain công ty:** Đổi thành `router-r1`, `core-sw01`, `company.local`.
5. **MAC Address / Serial Number:** Đổi thành `0000.5e00.0001` hoặc `SN12345678`.

---

## ✂️ 2. ĐOẠN REGEX LÀM SẠCH DATA (VS CODE & PYTHON & SED)

### A. Công cụ Regex dùng trực tiếp trong VS Code / Editor (Find & Replace)

Mở VS Code (`Ctrl + F` / `Cmd + F`), bật biểu tượng **Regex `.*`**:

| Hạng mục | Pattern (Find) | Replace With | Mô tả |
| :--- | :--- | :--- | :--- |
| **IPv4 Address** | `\b(?:(?:25[0-5]\|2[0-4][0-9]\|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]\|2[0-4][0-9]\|[01]?[0-9][0-9]?)\b` | `10.0.0.X` | Thay thế tất cả địa chỉ IP bằng `10.0.0.X` |
| **Cisco Passwords / Secrets** | `(?i)(password\|secret\|preshared-key\|community\|key-string)\s+(\d+\s+)?\S+` | `$1 [REDACTED]` | Ẩn password, secret, community string |
| **MAC Address** | `([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})\|([0-9a-fA-F]{4}\.[0-9a-fA-F]{4}\.[0-9a-fA-F]{4})` | `0000.5e00.0001` | Chuẩn hóa MAC address |
| **API Token / Secret Key** | `(?i)(token\|bearer\|api[_-]?key\|auth)\s*[:=]\s*["']?\S+["']?` | `$1: "[REDACTED_TOKEN]"` | Ẩn Token/API key |

---

### B. Python Script Tự Động Làm Sạch File Config / Log (`sanitize_config.py`)

Bạn có thể lưu và chạy script Python này để tự động làm sạch file config trước khi hỏi AI:

```python
#!/usr/bin/env python3
import re
import sys

def sanitize_network_data(text: str) -> str:
    # 1. Obfuscate Passwords, Secrets, Community Strings
    text = re.sub(
        r'(?i)(password|secret|preshared-key|community|key-string)\s+(\d+\s+)?\S+',
        r'\1 [REDACTED]',
        text
    )
    
    # 2. Obfuscate API Tokens & Bearer Keys
    text = re.sub(
        r'(?i)(token|bearer|api[_-]?key|auth)\s*[:=]\s*["\']?\S+["\']?',
        r'\1: "[REDACTED_TOKEN]"',
        text
    )

    # 3. Mask Public/Private IPv4 Addresses
    def mask_ip(match):
        ip = match.group(0)
        if ip.startswith("127.") or ip == "0.0.0.0" or ip == "255.255.255.255":
            return ip
        return "10.X.X.X"
    
    ip_pattern = r'\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b'
    text = re.sub(ip_pattern, mask_ip, text)
    
    # 4. Mask MAC Addresses
    mac_pattern = r'([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})|([0-9a-fA-F]{4}\.[0-9a-fA-F]{4}\.[0-9a-fA-F]{4})'
    text = re.sub(mac_pattern, '0000.5e00.0001', text)
    
    return text

if __name__ == "__main__":
    if len(sys.argv) > 1:
        with open(sys.argv[1], 'r', encoding='utf-8') as f:
            content = f.read()
        print(sanitize_network_data(content))
    else:
        print("Cách dùng: python3 sanitize_config.py <file_cautruc_network.conf>")
```

---

### C. Lệnh One-liner trong Linux Terminal (`sed`)

```bash
# Làm sạch password và IP từ file config.txt ra file config_clean.txt
sed -E 's/(password|secret|community) [^ ]+/\1 [REDACTED]/gI; s/([0-9]{1,3}\.){3}[0-9]{1,3}/10.X.X.X/g' config.txt > config_clean.txt
```

---

## 🚦 3. MA TRẬN KIỂM SOÁT AI (CONTROL MATRIX)

| Phân vùng | Loại công việc | Mức độ kiểm soát & Hành động |
| :--- | :--- | :--- |
| 🟢 **VÙNG XANH** *(Giao thoải mái)* | Giải thích khái niệm CCNA, tóm tắt RFC, gợi ý khung script Python/Ansible, soạn nháp báo cáo. | **Đọc lướt lại** như kiểm tra bài làm của đồng nghiệp mới. |
| 🟡 **VÙNG VÀNG** *(Giao nhưng phải kiểm tra)* | Phân tích Log/Show output, chẩn đoán nguyên nhân sự cố, gợi ý lệnh CLI cụ thể theo dòng OS. | **Đối chiếu tài liệu hãng & thử trên LAB (containerlab/EVE-NG)** trước khi gõ thật trên thiết bị Production. |
| 🔴 **VÙNG ĐỎ** *(TUYỆT ĐỐI CẤM)* | Copy lệnh AI sinh ra dán trực tiếp vào Production; dán mật khẩu/IP thật của công ty lên AI công cộng. | **KHÔNG CÓ NGOẠI LỆ.** Thói quen này ngăn ngừa 99% rủi ro sập mạng hoặc rò rỉ dữ liệu. |

---

## 📐 4. KHUNG PROMPT CHUẨN 6 BƯỚC CHO KỸ SƯ MẠNG (BUILDING BLOCKS)

```text
1. 👤 Role (Vai trò):     "Bạn là chuyên gia mạng Cisco CCIE / Network Automation Engineer..."
2. 🗺️ Context (Bối cảnh):  Thiết bị gì, dòng nào, OS bao nhiêu, vị trí sơ đồ mạng ra sao.
3. 📑 Data (Dữ liệu):     Dán output `show`, file log hoặc config (ĐÃ LÀM SẠCH IP/PASS).
4. 🎯 Task (Nhiệm vụ):    Muốn AI giải thích, khoanh vùng lỗi hay gợi ý script.
5. 📐 Format (Hình thức): Bảng 3 cột, danh sách từng bước hay đoạn code.
6. 🚧 Constraints (Ràng buộc): "Không chắc thì bảo không chắc; chưa đưa lệnh sửa vội."
```

---

## 💡 5. BỘ PROMPT "BỎ TÚI" CHO CÁC TÌNH HUỐNG THỰC TẾ

### 1️⃣ Khi chẩn đoán sự cố (Troubleshooting - Khóa lệnh sửa)
```text
Bối cảnh: Hệ thống router Cisco IOS-XE 17.6 chạy OSPF area 0.
Triệu chứng: Neighbor rơi vào trạng thái INIT liên tục.
Dữ liệu: [Dán output show ip ospf neighbor và show ip ospf interface]

Yêu cầu:
1. Đưa ra 3 giả thuyết nguyên nhân theo xác suất từ cao xuống thấp.
2. Mỗi giả thuyết đính kèm ĐÚNG 1 LỆNH show để tôi tự gõ kiểm chứng.
3. RÀNG BUỘC: Chưa đưa ra bất kỳ câu lệnh cấu hình (config t) sửa lỗi nào.
```

### 2️⃣ Khi đọc cấu hình lạ hoặc Audit Security
```text
Bối cảnh: Tôi vừa tiếp quản router biên Juniper JunOS.
Dữ liệu: [Dán config đã sanitize]

Yêu cầu:
1. Tóm tắt thiết bị này đang làm những nhiệm vụ gì chính.
2. Phân tích 3 điểm bất thường hoặc rủi ro bảo mật trong file config trên.
3. Trình bày dưới dạng Bảng 3 cột: [Hạng mục | Hiện trạng | Khuyến nghị].
```

### 3️⃣ Khi viết Script Python tự động hóa
```text
Yêu cầu: Viết một script Python dùng thư viện Netmiko để backup cấu hình cho 10 switch Cisco IOS.
Ràng buộc:
- Đọc danh sách IP từ file `devices.txt`.
- Sử dụng `try...except` để xử lý lỗi timeout hoặc sai password.
- Thêm comment bằng tiếng Việt giải thích từng khối code.
- Xuất kết quả ra thư mục `backups/` theo định dạng `HOSTNAME_YYYYMMDD.cfg`.
```

---

## 📊 6. GRAFANA MCP CHEAT SHEET

### Cấu hình Grafana MCP Client:
```json
{
  "mcpServers": {
    "grafana": {
      "command": "npx",
      "args": ["-y", "@grafana/mcp-server"],
      "env": {
        "GRAFANA_URL": "https://demo-2.9ping.cloud",
        "GRAFANA_SERVICE_ACCOUNT_TOKEN": "<YOUR_SERVICE_ACCOUNT_TOKEN>"
      }
    }
  }
}
```

### Prompts mẫu thao tác Grafana MCP:
* **Tạo Folder:** `"Dùng Grafana MCP tool tạo một Folder mới có tên 'HV_NguyenVanA_Dashboard'."`
* **Tạo Dashboard:** `"Dùng Grafana MCP tạo Dashboard 'Network Monitoring' trong Folder 'HV_NguyenVanA_Dashboard' gồm panel CPU/RAM, Port Status, và Băng thông WAN1/WAN2."`
* **Viết PromQL Băng thông:** `"Viết PromQL tính lưu lượng Download (Bit/s) từ metric counter ifHCInOctets cho interface eth1 trong 1 phút."` ➔ `rate(ifHCInOctets{instance="edge-gw", ifDescr="eth1"}[1m]) * 8`
