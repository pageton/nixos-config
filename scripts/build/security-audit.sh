#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

fail=0

log() {
  printf '%s\n' "$1" >&2
}

mark_fail() {
  fail=1
}

log "== Security audit: secret hygiene =="

for path in "secrets/secrets-decrypted.yaml" "home/secrets/secrets-decrypted.yaml"; do
  if [[ -f "$path" ]]; then
    log "[FAIL] Found decrypted secret file: $path"
    mark_fail
  else
    log "[OK] Not present: $path"
  fi
done

log "== Security audit: risky nix flags =="

if rg --glob '*.nix' --line-number --hidden --pcre2 '^\s*allowInsecure\s*=\s*true\s*;' .; then
  log "[FAIL] allowInsecure is enabled"
  mark_fail
fi

if rg --glob '*.nix' --line-number --hidden --pcre2 '^\s*allowBroken\s*=\s*true\s*;' .; then
  log "[FAIL] allowBroken is enabled"
  mark_fail
fi

if rg --glob '*.nix' --line-number --hidden --pcre2 '^\s*PermitRootLogin\s*=\s*"yes"\s*;' .; then
  log "[FAIL] SSH root login explicitly enabled"
  mark_fail
fi

if rg --glob '*.nix' --line-number --hidden --pcre2 '^\s*PasswordAuthentication\s*=\s*true\s*;' .; then
  log "[FAIL] SSH password auth explicitly enabled"
  mark_fail
fi

if rg --glob '*.nix' --line-number --hidden --pcre2 '^\s*wheelNeedsPassword\s*=\s*false\s*;' .; then
  log "[FAIL] sudo wheel password requirement is disabled"
  mark_fail
fi

if rg --glob '*.nix' --line-number --hidden --pcre2 'NOPASSWD\s*:\s*ALL' .; then
  log "[FAIL] Broad NOPASSWD:ALL sudo rule detected"
  mark_fail
fi

if rg --glob '*.nix' --line-number --hidden --pcre2 '^\s*openFirewall\s*=\s*true\s*;' .; then
  log "[WARN] openFirewall=true found; verify this is required"
fi

log "== Security audit: secret pattern scan =="

secret_pattern='(AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{36,255}|xox[baprs]-[A-Za-z0-9-]{10,}|-----BEGIN (RSA|EC|OPENSSH|PGP) PRIVATE KEY-----|password\s*=\s*"[^"]{8,}"|token\s*=\s*"[A-Za-z0-9._-]{16,}")'

if rg --line-number --hidden --pcre2 \
  --glob '!.git/**' \
  --glob '!flake.lock' \
  --glob '!secrets/secrets.yaml' \
  --glob '!home/secrets/secrets.yaml' \
  "$secret_pattern" .; then
  log "[FAIL] Suspicious plaintext secrets found"
  mark_fail
else
  log "[OK] No suspicious plaintext secret patterns found"
fi

log "== Security audit: gitignore guard =="

if [[ -f .gitignore ]]; then
  if rg --line-number --fixed-strings 'secrets-decrypted.yaml' .gitignore >/dev/null; then
    log "[OK] .gitignore protects decrypted secret files"
  else
    log "[WARN] .gitignore missing secrets-decrypted.yaml guard"
  fi
else
  log "[WARN] .gitignore not found"
fi

log "== Security audit: script permissions =="

if find scripts -type f -name '*.sh' -perm /022 | grep -q .; then
  find scripts -type f -name '*.sh' -perm /022
  log "[FAIL] World/group-writable shell scripts found"
  mark_fail
else
  log "[OK] No world/group-writable shell scripts"
fi

if ((fail > 0)); then
  log "== Security audit result: FAIL =="
  exit 1
fi

log "== Security audit result: PASS =="
