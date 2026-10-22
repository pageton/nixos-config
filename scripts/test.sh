#!/usr/bin/env bash
# Run the explicitly offline regression suites, never activation or live lab checks.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

for tool in python3 just bun node nix git tmux herdr; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf 'Missing regression prerequisite: %s. Run from nix develop with the managed apps available.\n' "$tool" >&2
    exit 1
  fi
done
python3 -B tests/pi_test_support.py

node --test tests/pi-subagents-recall.test.mjs
bun test tests/pi-network-diagnostics.test.ts
for suite in \
  herdr-backup pi-config pi-profiles pi-test-support pi-subagents pi-extensions pi-web-search pi-herdr \
  pi-upstream-retry pi-resume-dispatch \
  pi-re-config pi-re-rea pi-re-research pi-re-subagent pi-re-browser; do
  printf '\n== %s ==\n' "$suite"
  python3 -B "tests/$suite.py"
done
