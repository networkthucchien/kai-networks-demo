# Triển khai demo lên server lab

Dựng **demo-2 (giám sát mạng Grafana + SNMP)** trên server lab để học viên truy cập trực tiếp và xem.

- **Học viên xem:** <http://demo-2.9ping.cloud:8082/> — Grafana, ẩn danh, quyền Viewer, mở đúng dashboard ngay.
- **Giảng viên thao tác:** SSH vào server rồi dùng `make` trong thư mục này.

> demo-1 (VRRP/OSPF) hiện **chưa** đưa lên server — source vẫn nằm ở [`demo-1/`](../demo-1/) và chạy được tại chỗ theo [`demo-1/README.md`](../demo-1/README.md).

---

## Vì sao dùng cổng 8082 chứ không phải 80/443

Server đã có Traefik chiếm 80/443 phục vụ các ứng dụng khác (netconsole, workforce). Để **không đụng** vào cấu hình đang chạy, Grafana publish thẳng ở cổng riêng **8082**.

Hệ quả cần biết:

- Truy cập qua **HTTP, không có TLS**. Học viên chỉ xem dashboard nên không có dữ liệu nhạy cảm đi qua.
- **Không đăng nhập tài khoản admin Grafana qua Internet.** Khi cần sửa dashboard, dùng SSH tunnel:
  ```bash
  ssh -i ~/cbjs/keygen/id_rsa -L 8082:localhost:8082 ubuntu@clab.9ping.cloud
  # rồi mở http://localhost:8082/login  (user admin, mật khẩu trong deploy/.env)
  ```
- Firewall của server đang **inactive** (policy ACCEPT) — mọi cổng publish đều lộ thẳng ra Internet. Vì vậy **chỉ Grafana** được publish; Prometheus và snmp-exporter chỉ nghe trong mạng nội bộ Docker.

---

## Cài lần đầu

```bash
# 1. Đưa repo lên server (bỏ qua file sinh tự động)
rsync -az --delete --exclude '.git' --exclude '*.pptx' --exclude 'deploy/.env' \
  --exclude 'snmp_exporter/snmp.yml' --exclude 'snmp_exporter/mibs' \
  -e "ssh -i ~/cbjs/keygen/id_rsa" ./ ubuntu@clab.9ping.cloud:/home/ubuntu/kai-networks-demo/

# 2. Trên server: đặt mật khẩu admin Grafana
ssh -i ~/cbjs/keygen/id_rsa ubuntu@clab.9ping.cloud
cd /home/ubuntu/kai-networks-demo/deploy
cp .env.example .env && $EDITOR .env      # đặt GF_ADMIN_PASSWORD

# 3. Build image + sinh snmp.yml (chỉ cần chạy lại khi sửa generator.yml)
make prep

# 4. Deploy
make up
sleep 30 && make check
```

## Lệnh hằng ngày

| Lệnh | Việc |
| :--- | :--- |
| `make up` | Deploy lab + monitoring stack |
| `make check` | Kiểm tra từng chặng: snmpd → snmp_exporter → Prometheus → Grafana |
| `make status` | Xem node lab và container đang chạy |
| `make port-down` / `make port-up` | Kịch bản demo "Port Down" trên sân khấu |
| `make restart` | Dựng lại sạch trước buổi dạy |
| `make logs` | Log của snmp-exporter và Prometheus |
| `make down` | Dọn sạch |

`make check` phải xanh cả 5 mục trước khi lên lớp.

---

## Kiến trúc

```
isp1 100.64.11.1/30 ─┐
                     ├─ edge-gw ─ sw ─ host-a 10.0.20.100
isp2 100.64.12.1/30 ─┘  snmpd:161
                            │
                            │ SNMP v2c (community public)
                            ▼
                     snmp-exporter ──► Prometheus ──► Grafana :8082
                       (nội bộ)         (nội bộ)      (public)
```

`edge-gw` chạy sẵn `gen-traffic.sh` (iperf3) tới cả hai ISP nên hai kênh uplink luôn có băng thông "sống" trên dashboard.

Cách giám sát này **giống hệt** khi giám sát Cisco/MikroTik/Juniper thật — chỉ đổi target IP trong `prometheus.yml`.

---

## Các điểm đã phải sửa để chạy được (đọc trước khi đổi cấu hình)

Bốn lỗi thật gặp khi dựng lần đầu, đã fix trong repo:

1. **`generator.yml` dùng schema cũ.** `version: 2` không còn nằm trong module; SNMP version giờ khai ở khối `auths:`. Kèm theo, `prometheus.yml` phải truyền thêm `auth: [public_v2]`.

2. **Image `prom/snmp-generator` không có MIB IETF** — chỉ đóng gói MIB của NET-SNMP/UCD. [`fetch-mibs.sh`](../demo-2/monitoring/snmp_exporter/fetch-mibs.sh) tải IF-MIB, HOST-RESOURCES-MIB, UCD-SNMP-MIB… từ repo net-snmp (ghim tag `v5.9.4`). `generate.sh` đặt `MIBDIRS=/opt/mibs` — **không** nạp MIB vendor có sẵn trong image vì chúng thiếu phụ thuộc riêng và làm generator abort.

3. **snmpd không khởi động được.** Lệnh cũ `snmpd -c /etc/snmp/snmpd.conf` khiến file bị đọc **hai lần** (một lần từ đường dẫn mặc định, một lần từ `-c`) → `agentAddress udp:161` khai trùng → `Error opening specified endpoint "udp:161"` → snmpd exit code 1, cổng 161 `connection refused`. Fix: thêm cờ **`-C`** trong `network-monitoring.clab.yml`.

4. **`hrProcessorLoad` luôn rỗng.** net-snmp trong container không populate `hrProcessorTable` (`No Such Instance`) dù `hrDeviceTable` vẫn liệt kê đủ CPU. Panel CPU chuyển sang `100 - ssCpuIdle` của UCD-SNMP-MIB. Khi đổi target sang thiết bị mạng thật (Cisco/MikroTik có `hrProcessorLoad`), thêm lại OID đó vào `generator.yml`.

`snmp.yml` và `mibs/` là **file sinh tự động** — không commit, không rsync. Chạy `make prep` để tạo lại.
