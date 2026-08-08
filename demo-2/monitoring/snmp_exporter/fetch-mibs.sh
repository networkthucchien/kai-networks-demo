#!/bin/sh
# Tải các MIB chuẩn IETF về thư mục mibs/.
#
# Image prom/snmp-generator chỉ đóng gói sẵn MIB của NET-SNMP/UCD — không có
# IF-MIB (port + băng thông) và HOST-RESOURCES-MIB (CPU/RAM/Disk) mà generator.yml cần.
# Nguồn: repo net-snmp, ghim theo tag để kết quả sinh ra ổn định giữa các lần chạy.
set -e
cd "$(dirname "$0")"

NETSNMP_TAG=v5.9.4
BASE="https://raw.githubusercontent.com/net-snmp/net-snmp/${NETSNMP_TAG}/mibs"

# SNMPv2-* là MIB nền mọi MIB khác import.
# IANAifType-MIB là phụ thuộc bắt buộc của IF-MIB.
# UCD-SNMP-MIB dùng cho CPU: net-snmp trong container KHÔNG populate hrProcessorTable
# của HOST-RESOURCES-MIB, nên chỉ số CPU lấy từ ssCpu*/laLoad của UCD.
# HCNUM-TC là phụ thuộc của UCD-SNMP-MIB.
MIBS="SNMPv2-SMI SNMPv2-TC SNMPv2-CONF SNMPv2-MIB
      IANAifType-MIB IF-MIB
      HOST-RESOURCES-MIB HOST-RESOURCES-TYPES
      HCNUM-TC UCD-SNMP-MIB"

mkdir -p mibs
for m in $MIBS; do
    if [ -s "mibs/${m}.txt" ]; then
        echo "  đã có   ${m}.txt"
        continue
    fi
    echo "  tải     ${m}.txt"
    curl -fsSL "${BASE}/${m}.txt" -o "mibs/${m}.txt"
done

echo "Xong. MIB nằm ở monitoring/snmp_exporter/mibs/"
