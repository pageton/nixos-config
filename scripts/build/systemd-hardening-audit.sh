#!/usr/bin/env bash
set -euo pipefail
echo "=== Systemd Service Hardening Audit ==="
echo ""
echo "Services with ambient capabilities:"
systemd-analyze security 2>/dev/null | sort -t' ' -k2 -n || echo "systemd-analyze security not available"
echo ""
echo "Hardening audit completed."
