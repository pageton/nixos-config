#!/usr/bin/env bash
set -euo pipefail

services=(
  "sshd.service"
  "tailscaled.service"
  "NetworkManager.service"
  "netdata.service"
  "scrutiny.service"
  "scrutiny-collector.service"
  "influxdb2.service"
)

echo "== Systemd hardening audit =="

for svc in "${services[@]}"; do
  if systemctl list-unit-files --type=service --no-legend | grep -q "^${svc%%.service}"; then
    echo
    echo "--- $svc ---"
    systemd-analyze security "$svc" || true
  fi
done

echo
echo "== Hardening audit complete =="
