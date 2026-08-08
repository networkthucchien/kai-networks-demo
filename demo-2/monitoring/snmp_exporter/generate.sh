#!/bin/sh
# Sinh snmp.yml từ generator.yml bằng image generator chính thức của snmp_exporter.
# Chạy 1 lần trước khi "docker compose up" lần đầu (hoặc mỗi khi sửa generator.yml).
set -e
cd "$(dirname "$0")"

# MIB chuẩn IETF không có sẵn trong image generator — tải về trước (chỉ lần đầu).
./fetch-mibs.sh

# MIBDIRS chỉ trỏ vào mibs/ vừa tải. Không nạp MIB vendor đóng gói sẵn trong image
# (UCD-SNMP-MIB, NET-SNMP-*) — chúng thiếu phụ thuộc riêng và làm generator báo lỗi parse,
# trong khi generator.yml không hề dùng tới chúng.
docker run --rm -v "$(pwd):/opt" -w /opt \
    -e MIBDIRS=/opt/mibs \
    prom/snmp-generator:latest generate

echo "Đã sinh monitoring/snmp_exporter/snmp.yml"
