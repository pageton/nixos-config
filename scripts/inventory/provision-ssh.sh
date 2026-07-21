#!/usr/bin/env bash
# provision-ssh.sh — Upload SSH public key to all inventory servers.
#
# Reads inventory/permanent/servers.nix and inventory/ephemeral/servers.nix,
# checks which servers already have the key, and uploads to the rest.
#
# Usage: scripts/inventory/provision-ssh.sh [hostname]
#   No args  → provision all servers in inventory
#   hostname → provision only that server
#
# First connection requires the root password (entered interactively).
# After that, key-based auth is used for all future connections.

set -euo pipefail

# ─── Paths ────────────────────────────────────────────────────────
SYSTEM_DIR="${HOME}/System"
PERMANENT="${SYSTEM_DIR}/inventory/permanent/servers.nix"
EPHEMERAL="${SYSTEM_DIR}/inventory/ephemeral/servers.nix"
MARKER_DIR="${HOME}/.ssh/provisioned"
PUBKEY="${HOME}/.ssh/id_ed25519.pub"
JQ="${JQ:-jq}"

# ─── Checks ───────────────────────────────────────────────────────
if ! command -v nix &>/dev/null; then
  echo "ERROR: nix not found on PATH" >&2
  exit 1
fi

if [ ! -f "${PUBKEY}" ]; then
  echo "ERROR: SSH public key not found at ${PUBKEY}" >&2
  exit 1
fi

mkdir -p "${MARKER_DIR}"

# ─── Collect servers from inventory ───────────────────────────────
collect_servers() {
  local file="$1"
  [ -f "${file}" ] || return 0
  nix eval --impure --json --expr "import \"${file}\"" 2>/dev/null
}

# Start with empty array, merge each inventory file.
SERVERS_JSON="[]"
for f in "${PERMANENT}" "${EPHEMERAL}"; do
  if [ -f "${f}" ]; then
    batch="$(collect_servers "${f}")"
    if [ -n "${batch}" ]; then
      SERVERS_JSON="$(jq --argjson b "${batch}" '. + $b' <<<"${SERVERS_JSON}")"
    fi
  fi
done

# If a hostname filter is provided, narrow to just that server.
if [ $# -gt 0 ]; then
  SERVERS_JSON="$(jq --arg h "$1" '[.[] | select(.hostname == $h)]' <<<"${SERVERS_JSON}")"
fi

COUNT="$(jq 'length' <<<"${SERVERS_JSON}")"
if [ "${COUNT}" -eq 0 ]; then
  echo "No servers found in inventory."
  exit 0
fi

# ─── Read servers into bash array (avoids ssh swallowing loop stdin) ──
mapfile -t SERVER_ROWS < <(jq -r '.[] | [.hostname, .ip, (.user // "root")] | @tsv' <<<"${SERVERS_JSON}")

# ─── Provision each server ────────────────────────────────────────
echo "SSH public key: $(cat "${PUBKEY}")"
echo "Found ${COUNT} server(s) in inventory."
echo ""

provisioned=0
skipped=0
failed=0

for row in "${SERVER_ROWS[@]}"; do
  IFS=$'\t' read -r hostname ip user <<<"${row}"
  marker="${MARKER_DIR}/${hostname}"

  # Check if already provisioned.
  if [ -f "${marker}" ]; then
    echo "  SKIP   ${hostname} (${ip}) — already provisioned"
    skipped=$((skipped + 1))
    continue
  fi

  # Check if key-based auth already works (server may have been set up manually).
  if ssh -n -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${user}@${ip}" 'true' 2>/dev/null; then
    touch "${marker}"
    echo "  SKIP   ${hostname} (${ip}) — key already authorized"
    skipped=$((skipped + 1))
    continue
  fi

  # Upload key (prompts for password on first connection).
  echo "  UPLOAD ${hostname} (${ip}) — enter password for ${user}@${ip}:"
  if ssh-copy-id -i "${PUBKEY}" -o StrictHostKeyChecking=no "${user}@${ip}"; then
    touch "${marker}"
    echo "  OK     ${hostname} — key uploaded"
    provisioned=$((provisioned + 1))
  else
    echo "  FAIL   ${hostname} — upload failed"
    failed=$((failed + 1))
  fi
done

# ─── Summary ──────────────────────────────────────────────────────
echo ""
echo "Done: ${provisioned} uploaded, ${skipped} skipped, ${failed} failed."
