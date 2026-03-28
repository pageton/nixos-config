#!/usr/bin/env bash
set -euo pipefail

top_services="${1:-15}"

printf '== Performance audit: system boot ==\n'
systemd-analyze time || true

printf '\nTop %s boot blockers (system):\n' "$top_services"
systemd-analyze blame | head -n "$top_services" || true

printf '\nCritical chain (system):\n'
systemd-analyze critical-chain || true

printf '\n== Performance audit: user session ==\n'
if systemctl --user is-system-running >/dev/null 2>&1; then
  printf 'Running user services:\n'
  systemctl --user list-units --type=service --state=running --no-pager || true

  printf '\nNiri/Noctalia related user units:\n'
  systemctl --user list-unit-files --no-pager | grep -E 'niri|noctalia|polkit|xwayland|wl-clip|cliphist' || true
else
  printf '[WARN] No active user systemd session detected\n'
fi

printf '\n== Performance audit: closure size ==\n'
hostname_value="$(hostname)"
if nix path-info -S ".#nixosConfigurations.${hostname_value}.config.system.build.toplevel" 2>/dev/null; then
  :
elif nix path-info -S .#nixosConfigurations.desktop.config.system.build.toplevel 2>/dev/null; then
  printf '[WARN] Local hostname not in flake; reported desktop closure instead\n'
elif nix path-info -S .#nixosConfigurations.thinkpad.config.system.build.toplevel 2>/dev/null; then
  printf '[WARN] Local hostname not in flake; reported thinkpad closure instead\n'
else
  printf '[WARN] Could not evaluate host closure size\n'
fi

printf '\n== Performance audit complete ==\n'
