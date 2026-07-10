#!/usr/bin/env bash
# fetch-progress.sh - Live progress for in-flight fetchurl downloads.
#
# During a long `nh os switch`, the big CDN blobs (NVIDIA driver ~404 MB,
# Android Studio ~1.2 GB) resume across connection drops. The per-retry curl
# progress bar resets on every retry, so net progress is hard to read. This
# script watches the nix-daemon's curl build processes via /proc and shows each
# download's accumulated byte count + rate — monotonic across retries, so you
# can confirm resume is actually converging instead of stuck looping.
#
# Note: only fetchurl-BUILD downloads use curl; substituter pulls (cache.nixos.org)
# use Nix's internal downloader and won't appear here. That's exactly the split
# you want — this shows the two blobs that were failing.
#
# Usage: just fetch-progress   (or: sudo bash scripts/build/fetch-progress.sh)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"

[[ "${EUID}" -eq 0 ]] || error_exit "must run as root to read build-process /proc — use: sudo bash $0"

hr() { numfmt --to=iec --suffix=B "$1" 2>/dev/null || echo "${1}B"; }

declare -A prev
print_info "watching fetchurl downloads — Ctrl+C to stop"

while true; do
	clear
	active=0
	printf '%-34s %14s %14s  %s\n' "FILE" "DOWNLOADED" "RATE" "PID"
	printf '%-34s %14s %14s  %s\n' "----------------------------------" "--------------" "--------------" "------"
	while IFS= read -r pid; do
		[[ -n "${pid}" ]] || continue
		active=1
		# Largest regular file this curl has open == its -o download target.
		f=$(find -L "/proc/${pid}/fd" -xtype f -printf '%s %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
		[[ -z "${f}" ]] && continue
		bytes=$(stat -c %s "${f}" 2>/dev/null || echo 0)
		base=$(basename "${f}")
		if [[ -z "${base}" || "${base}" == "${f}" ]]; then
			url=$(tr '\0' ' ' < "/proc/${pid}/cmdline" 2>/dev/null | grep -oE 'https?://[^ ]+' | tail -1)
			base=${url##*/}
		fi
		pb=${prev[${pid}]:-0}
		delta=$(( bytes - pb ))
		(( delta < 0 )) && delta=0
		rate=$(( delta / 2 ))
		printf '%-34.34s %14s %14s\n' "${base}" "$(hr "${bytes}")" "$(hr "${rate}")/s"
		prev[${pid}]=${bytes}
	done < <(pgrep -x curl)
	[[ "${active}" -eq 0 ]] && print_warning "no active curl fetch right now (build is compiling / extracting / substituting)"
	printf '\n%s\n' "$(date +%H:%M:%S)"
	sleep 2
done
