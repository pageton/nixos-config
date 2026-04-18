#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/logging.sh
source "${SCRIPT_DIR}/../lib/logging.sh"
# shellcheck source=scripts/lib/require.sh
source "${SCRIPT_DIR}/../lib/require.sh"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

need_cmd rg

print_info "Scanning repository for risky security artifacts..."

artifact_report="${TMP_DIR}/artifact-report.txt"
content_report="${TMP_DIR}/content-report.txt"

rg \
  --files \
  --hidden \
  -g '!**/.git/**' \
  -g '!flake.lock' \
  -g '!secrets/secrets.yaml' \
  -g '!**/*.age' \
  -g '!**/*.sops.*' \
  -g '!**/*.asc' \
  -g '!**/*-test.sh' \
  -g '!**/testdata/**' \
  -g '!**/fixtures/**' \
  -g '.env' \
  -g '.env.*' \
  -g 'id_rsa' \
  -g 'id_ed25519' \
  -g 'credentials.json' \
  -g '*.pem' \
  -g '*.key' \
  -g '*.p12' \
  -g '*.pfx' \
  . >"${artifact_report}" || true

rg \
  --line-number \
  --hidden \
  --glob '!**/.git/**' \
  --glob '!flake.lock' \
  --glob '!secrets/secrets.yaml' \
  --glob '!**/*.age' \
  --glob '!**/*.sops.*' \
  --glob '!**/*.asc' \
  --glob '!**/*-test.sh' \
  --glob '!**/testdata/**' \
  --glob '!**/fixtures/**' \
  --regexp 'BEGIN (RSA|DSA|EC|OPENSSH|PGP|PRIVATE) PRIVATE KEY' \
  . >"${content_report}" || true

failures=0

if [[ -s "${artifact_report}" ]]; then
  print_error "Potential secret-bearing files found:"
  cat "${artifact_report}"
  failures=1
fi

if [[ -s "${content_report}" ]]; then
  print_error "Private key material detected in repository text:"
  cat "${content_report}"
  failures=1
fi

if (( failures > 0 )); then
  error_exit "security audit failed"
fi

print_success "No risky security artifacts or plaintext key material found."
