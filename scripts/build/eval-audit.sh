#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"
FLAKE_REF="path:$ROOT_DIR"
TARGET="${1:-all}"
HM_USER="${2:-sadiq}"

known_hosts=(desktop thinkpad)
selected_hosts=()

if [[ "$TARGET" == "all" ]]; then
  selected_hosts=("${known_hosts[@]}")
else
  selected_hosts=("$TARGET")
fi

timestamp_ms() {
  date +%s%3N
}

run_step() {
  local label="$1"
  shift
  local start end elapsed

  start="$(timestamp_ms)"
  "$@"
  end="$(timestamp_ms)"
  elapsed=$((end - start))

  printf '%-42s %6d ms\n' "$label" "$elapsed"
}

echo "== Evaluation audit (no switch) =="

for host in "${selected_hosts[@]}"; do
  run_step "nixos ${host} eval" \
    nix eval "$FLAKE_REF#nixosConfigurations.${host}.config.system.build.toplevel.drvPath" --quiet

  run_step "home ${host} eval" \
    nix eval "$FLAKE_REF#homeConfigurations.${HM_USER}@${host}.activationPackage.drvPath" --quiet
done

if [[ "$TARGET" == "all" ]]; then
  run_step "flake check --no-build" \
    nix flake check --no-build --quiet "$FLAKE_REF"
else
  echo "flake check --no-build                       skipped (target mode)"
fi

echo "== Evaluation audit complete =="
