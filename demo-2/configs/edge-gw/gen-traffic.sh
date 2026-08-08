#!/bin/sh
# Sinh traffic liên tục qua 2 uplink (eth1 -> isp1, eth2 -> isp2) để counters SNMP
# (ifHCInOctets/ifHCOutOctets) trên edge-gw thay đổi liên tục khi demo.
# Chạy nền, không thoát trừ khi bị kill.

ETH1_IP=$(ip -4 -o addr show dev eth1 | awk '{print $4}' | cut -d/ -f1)
ETH2_IP=$(ip -4 -o addr show dev eth2 | awk '{print $4}' | cut -d/ -f1)

while true; do
    iperf3 -c isp1 -B "$ETH1_IP" -t 8 >/dev/null 2>&1
    sleep 1
    iperf3 -c isp2 -B "$ETH2_IP" -t 8 >/dev/null 2>&1
    sleep 1
done
