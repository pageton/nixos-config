#!/usr/bin/env bash
# fetch-retry.sh - Harden the running nix-daemon against flaky-network downloads.
#
# Two independent download paths fail on a link that drops long-lived TLS
# streams, and each needs its own runtime override because nixos/modules/nix.nix
# only takes effect AFTER a successful `nh os switch` (catch-22: the build that
# would activate those settings runs under the old daemon).
#
#   1. fetchurl (build-phase curl, e.g. the NVIDIA .run / Android Studio tarball)
#      -> NIX_CURL_FLAGS is in fetchurl's impureEnvVars and is appended last in
#         builder.sh, so "--retry 100 -C -" wins: resumable retries.
#   2. substituter (cache.nixos.org nar pulls, Nix's internal libcurl downloader)
#      -> NIX_CONFIG="http2 = false" overrides nix.conf for the daemon, forcing
#         HTTP/1.1 so a TCP reset fails only one nar (then retried) instead of
#         bursting "Stream error in the HTTP/2 framing layer" across many.
#
# Idempotent and runtime-only (tmpfs /run, cleared on reboot). The module
# regenerates the unit with both vars permanently on the next successful switch.
#
# Usage: just fetch-retry   (or: sudo bash scripts/build/fetch-retry.sh)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
# shellcheck disable=SC1091
# shellcheck source=scripts/lib/require.sh
source "${SCRIPT_DIR}/../lib/require.sh"

# Must stay in sync with nixos/modules/nix.nix.
CURL_FLAGS="--retry 100 --retry-delay 3 -C -"
NIX_CONFIG_VAL="http2 = false"

[[ "${EUID}" -eq 0 ]] || error_exit "must run as root — use: sudo bash $0"
need_cmd systemctl

# Clear any prior runtime drop-in (e.g. a half-written file from a botched paste).
rm -rf "/run/systemd/system/nix-daemon.service.d"

# Apply both runtime overrides via stdin — heredoc-free and paste-safe.
# systemd Environment= can't hold the newline NIX_CONFIG needs for multiple
# settings, so only http2 (the decisive lever) is bridged here; download-attempts
# lands via nix.settings on the next switch.
printf '[Service]\nEnvironment="NIX_CURL_FLAGS=%s"\nEnvironment="NIX_CONFIG=%s"\n' \
	"${CURL_FLAGS}" "${NIX_CONFIG_VAL}" \
	| systemctl edit --runtime --stdin nix-daemon

systemctl daemon-reload
systemctl restart nix-daemon

# Verify both flags reached the running daemon's environment.
env_line=$(systemctl show nix-daemon -p Environment)
ok=1
if grep -q -- "NIX_CURL_FLAGS=${CURL_FLAGS}" <<<"${env_line}"; then
	print_success "NIX_CURL_FLAGS='${CURL_FLAGS}'"
else
	print_error "NIX_CURL_FLAGS missing"
	ok=0
fi
if grep -q -- "NIX_CONFIG=${NIX_CONFIG_VAL}" <<<"${env_line}"; then
	print_success "NIX_CONFIG='${NIX_CONFIG_VAL}'"
else
	print_error "NIX_CONFIG missing"
	ok=0
fi
if [[ "${ok}" -ne 1 ]]; then
	systemctl show nix-daemon -p Environment >&2
	exit 1
fi

print_info "now re-run your build: just nixos"
