# Triển khai demo-2 (giám sát mạng Grafana + SNMP) trên server lab.
#
#   make prep    # lần đầu: build image edge-gw, tải MIB, sinh snmp.yml
#   make up      # deploy lab + monitoring stack
#   make check   # kiểm tra toàn bộ đường dữ liệu SNMP -> Prometheus -> Grafana
#   make down    # dọn sạch
#
# Học viên xem tại:  http://demo-2.9ping.cloud:8082/   (Grafana, anonymous Viewer)
#
# Chỉ Grafana publish ra ngoài ở cổng 8082. Prometheus và snmp-exporter chỉ nghe
# trong mạng nội bộ — firewall server đang inactive nên mọi cổng publish đều lộ
# thẳng ra Internet.

SHELL := /bin/bash
ROOT  := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
CLAB  := $(ROOT)/demo-2/topology/network-monitoring.clab.yml
DC    := docker compose --env-file $(ROOT)/deploy/.env -f $(ROOT)/deploy/demo-2/docker-compose.yml
GW    := clab-network-monitoring-lab-edge-gw

.PHONY: prep up down restart status check logs port-down port-up

## Chuẩn bị lần đầu: build image edge-gw, tải MIB IETF, sinh snmp.yml
prep:
	@test -f $(ROOT)/deploy/.env || { echo "THIẾU deploy/.env — copy từ .env.example rồi đặt GF_ADMIN_PASSWORD"; exit 1; }
	docker build -t demo2-edge-gw:latest -f $(ROOT)/demo-2/images/edge-gw.Dockerfile $(ROOT)/demo-2/images
	cd $(ROOT)/demo-2/monitoring/snmp_exporter && ./generate.sh

## Deploy lab + monitoring stack
up:
	@ss -tln 2>/dev/null | grep -q ':8082 ' && { echo "!! CỔNG 8082 ĐANG BỊ CHIẾM"; exit 1; } || true
	sudo containerlab deploy --reconfigure -t $(CLAB)
	$(DC) up -d
	@echo; echo "  Grafana -> http://demo-2.9ping.cloud:8082/"
	@echo "  Chờ ~30s cho Prometheus scrape lần đầu, rồi: make check"

## Dựng lại từ đầu
restart: down up

down:
	-$(DC) down
	-sudo containerlab destroy -t $(CLAB)

status:
	@sudo containerlab inspect -t $(CLAB) 2>/dev/null || true
	@echo; docker ps --filter name=demo2- --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

## Kiểm tra từng chặng của đường dữ liệu — chạy sau `make up`
check:
	@echo "--- 1. snmpd nghe trên edge-gw ---"
	@docker exec $(GW) ss -ulnp 2>/dev/null | grep -q ':161 ' \
		&& echo "   OK  udp/161" || { echo "   LỖI snmpd không chạy"; exit 1; }
	@echo "--- 2. snmpd trả OID ifOperStatus ---"
	@docker exec $(GW) snmpwalk -v2c -c public localhost 1.3.6.1.2.1.2.2.1.8 2>/dev/null \
		| head -3 | sed 's/^/   /'
	@echo "--- 3. Prometheus scrape target ---"
	@docker exec demo2-prometheus wget -qO- 'http://localhost:9090/api/v1/query?query=up{job="snmp"}' \
		| grep -q '"value".*"1"' && echo "   OK  target UP" || echo "   LỖI target DOWN — xem: make logs"
	@echo "--- 4. Metric đã vào Prometheus ---"
	@for m in ifOperStatus ifHCInOctets ifHCOutOctets ssCpuIdle hrStorageUsed; do \
		n=$$(docker exec demo2-prometheus wget -qO- "http://localhost:9090/api/v1/query?query=count($$m)" \
			| grep -oE '"value":\[[^]]*,"[0-9]+"' | grep -oE '[0-9]+"$$' | tr -d '"'); \
		printf "   %-16s %s series\n" "$$m" "$${n:-0}"; \
	done
	@echo "--- 5. Grafana ---"
	@curl -fsS -m5 http://localhost:8082/api/health | sed 's/^/   /'

logs:
	$(DC) logs --tail=30 snmp-exporter prometheus

## Kịch bản demo "Port Down": panel WAN1 chuyển đỏ trong 1 chu kỳ scrape (15s)
port-down:
	docker exec $(GW) ip link set eth1 down
	@echo "eth1 (WAN1) đã down — theo dõi dashboard."

port-up:
	docker exec $(GW) ip link set eth1 up
	@echo "eth1 (WAN1) đã up trở lại."
