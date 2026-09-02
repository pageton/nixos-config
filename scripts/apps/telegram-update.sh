#!/usr/bin/env bash
# Bump the Telegram Desktop pin (tgVersion/tgHash) in
# home/programs/telegram.nix to the latest tdesktop GitHub release, then apply
# it — but only when the working tree was clean before the bump, so no
# unreviewed WIP rides along on an unattended `just home`.
#
# The hash comes from the release asset's official `digest` field (converted
# to SRI), so there is no "build fails, paste the hash" round-trip. Run daily
# by the telegram-update timer (home/programs/telegram.nix); also safe to run
# manually. Never commits — the bump stays in the working tree for review.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../lib/logging.sh
source "$SCRIPT_DIR/../lib/logging.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PIN_FILE="$REPO_ROOT/home/programs/telegram.nix"
API_URL="https://api.github.com/repos/telegramdesktop/tdesktop/releases/latest"

notify() {
  local urgency="$1" message="$2"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -u "$urgency" -a "telegram-update" "$message" >/dev/null 2>&1 || true
  fi
}

log_info "checking latest tdesktop release"
release_json="$(curl -fsSL --max-time 30 "$API_URL")"

tag="$(printf '%s' "$release_json" | jq -r '.tag_name // empty')"
version="${tag#v}"
if [[ ! "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
  log_error "unexpected tag from GitHub API: '${tag}'"
  exit 1
fi

current="$(sed -n 's/^  tgVersion = "\(.*\)";$/\1/p' "$PIN_FILE" | head -n1)"
if [[ -z "$current" ]]; then
  log_error "tgVersion pin not found in $PIN_FILE"
  exit 1
fi
if [[ "$version" == "$current" ]]; then
  log_info "pin already at latest ($version)"
  exit 0
fi

asset_digest="$(
  printf '%s' "$release_json" |
    jq -r --arg asset "tsetup.${version}.tar.xz" \
      '.assets[] | select(.name == $asset) | .digest // empty' |
    head -n1
)"
if [[ "$asset_digest" != sha256:* ]]; then
  log_error "no sha256 digest published for tsetup.${version}.tar.xz"
  exit 1
fi
hash_sri="$(nix hash convert --hash-algo sha256 --to sri "${asset_digest#sha256:}")"

# Only auto-switch when the tree was clean before this script touched it —
# otherwise `just home` would build unrelated WIP into the activation.
was_clean=0
if [[ -z "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)" ]]; then
  was_clean=1
fi

sed -i "s|^  tgVersion = \".*\";|  tgVersion = \"$version\";|" "$PIN_FILE"
sed -i "s|^  tgHash = \".*\";|  tgHash = \"$hash_sri\";|" "$PIN_FILE"
log_success "pin bumped: $current -> $version"

if (( ! was_clean )); then
  log_warning "working tree was dirty — skipping auto-switch (run 'just home' after committing)"
  notify normal "Telegram $version pinned; tree dirty — run 'just home' to apply"
  exit 0
fi

# Serialize against zcode-update.sh: whoever holds the lock rebuilds the whole
# flake, so the other's fresh pin rides along in the same switch.
lock_file="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hm-auto-switch.lock"
exec 9>"$lock_file"
if ! flock -n 9; then
  log_info "another home switch is in flight — its rebuild includes this pin"
  exit 0
fi

log_info "applying via just home"
if (cd "$REPO_ROOT" && just home); then
  log_success "switched to Telegram $version"
  notify normal "Telegram updated to $version"
else
  log_error "just home failed — pin is bumped but not applied"
  notify critical "Telegram update to $version FAILED (just home)"
  exit 1
fi
