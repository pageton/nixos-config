#!/usr/bin/env bash
# Bump the ZCode Desktop pin (version/sha256) in
# home/programs/ai-agents/zcode-package.nix to the release published on
# zcode.z.ai, then apply it — same contract as telegram-update.sh: switch only
# when the working tree was clean before the bump, never commit, and the home
# switch is serialized against other *-update timers via flock.
#
# ZCode publishes no machine-readable release feed (the bundled app-update.yml
# points at a dev localhost; no latest-linux.yml on either CDN), so "latest" =
# the highest ZCode-<semver>-linux-x64.AppImage version referenced by the
# download page. The hash comes from `nix store prefetch-file`, which also
# warms the store for the switch. Run daily by the zcode-update timer
# (home/programs/ai-agents/services.nix); also safe to run manually.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PIN_FILE="$REPO_ROOT/home/programs/ai-agents/zcode-package.nix"
CDN_URL_BASE="https://cdn-zcode.z.ai/zcode/electron/releases"
DOWNLOAD_PAGE="https://zcode.z.ai"

notify() {
  local urgency="$1" message="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u "$urgency" -a "zcode-update" "$message" >/dev/null 2>&1 || true
  fi
}

log_info "checking latest ZCode release on the download page"
page="$(curl -fsSL --max-time 30 "$DOWNLOAD_PAGE")"
version="$(
  printf '%s' "$page" |
    grep -oE '[0-9]+(\.[0-9]+)+/linux-x64|ZCode-[0-9]+(\.[0-9]+)+-linux-x64' |
    grep -oE '[0-9]+(\.[0-9]+)+' |
    sort -Vu |
    tail -n1
)"
if [[ ! "$version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
  log_error "could not parse a linux-x64 version from $DOWNLOAD_PAGE"
  exit 1
fi

current="$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$PIN_FILE" | head -n1)"
if [[ -z "$current" ]]; then
  log_error "version pin not found in $PIN_FILE"
  exit 1
fi
if [[ "$version" == "$current" ]]; then
  log_info "pin already at latest ($version)"
  exit 0
fi

# The page may reference versions the CDN has rotated away — verify before
# touching the pin.
url="$CDN_URL_BASE/$version/linux-x64/ZCode-$version-linux-x64.AppImage"
http_code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 -I "$url")"
if [[ "$http_code" != "200" && "$http_code" != "302" ]]; then
  log_error "CDN does not serve the new version yet (HTTP $http_code): $url"
  notify critical "ZCode $version published but CDN missing it (HTTP $http_code)"
  exit 1
fi

log_info "prefetching $url for the pin hash (also warms the store)"
hash_sri="$(nix store prefetch-file --json "$url" | jq -r '.hash')"

# Only auto-switch when the tree was clean before this script touched it —
# otherwise `just home` would build unrelated WIP into the activation.
was_clean=0
if [[ -z "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)" ]]; then
  was_clean=1
fi

sed -i "s|^  version = \".*\";|  version = \"$version\";|" "$PIN_FILE"
sed -i "s|^  sha256 = \".*\";|  sha256 = \"$hash_sri\";|" "$PIN_FILE"
log_success "pin bumped: $current -> $version"

if (( ! was_clean )); then
  log_warning "working tree was dirty — skipping auto-switch (run 'just home' after committing)"
  notify normal "ZCode $version pinned; tree dirty — run 'just home' to apply"
  exit 0
fi

# Serialize against telegram-update.sh: whoever holds the lock rebuilds the
# whole flake, so the other's fresh pin rides along in the same switch.
lock_file="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hm-auto-switch.lock"
exec 9>"$lock_file"
if ! flock -n 9; then
  log_info "another home switch is in flight — its rebuild includes this pin"
  exit 0
fi

log_info "applying via just home"
if (cd "$REPO_ROOT" && just home); then
  log_success "switched to ZCode $version"
  notify normal "ZCode updated to $version"
else
  log_error "just home failed — pin is bumped but not applied"
  notify critical "ZCode update to $version FAILED (just home)"
  exit 1
fi
