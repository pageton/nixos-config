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

# Run a single eval step in the background, writing timing to a temp file.
# Usage: run_step_bg <label> <outfile> <cmd...>
run_step_bg() {
  local label="$1"
  local outfile="$2"
  shift 2
  (
    local start end elapsed rc=0
    start="$(timestamp_ms)"
    "$@" >/dev/null || rc=$?
    end="$(timestamp_ms)"
    elapsed=$((end - start))
    printf '%-42s %6d ms\n' "$label" "$elapsed" > "$outfile"
    exit "$rc"
  ) &
}

echo "== Evaluation audit (no switch) =="

cleanup_files=()
cleanup() { rm -f "${cleanup_files[@]}"; }
trap cleanup EXIT

if [[ "${#selected_hosts[@]}" -le 1 ]]; then
  # Single host — run sequentially (unchanged behaviour)
  for host in "${selected_hosts[@]}"; do
    run_step "nixos ${host} eval" \
      nix eval "$FLAKE_REF#nixosConfigurations.${host}.config.system.build.toplevel.drvPath" --quiet

    run_step "home ${host} eval" \
      nix eval "$FLAKE_REF#homeConfigurations.${HM_USER}@${host}.activationPackage.drvPath" --quiet
  done
else
  # Multiple hosts — eval all in parallel
  pids=()
  labels=()

  for host in "${selected_hosts[@]}"; do
    local_nixos_out=$(mktemp)
    local_home_out=$(mktemp)
    cleanup_files+=("$local_nixos_out" "$local_home_out")

    run_step_bg "nixos ${host} eval" "$local_nixos_out" \
      nix eval "$FLAKE_REF#nixosConfigurations.${host}.config.system.build.toplevel.drvPath" --quiet
    pids+=($!)

    run_step_bg "home ${host} eval" "$local_home_out" \
      nix eval "$FLAKE_REF#homeConfigurations.${HM_USER}@${host}.activationPackage.drvPath" --quiet
    pids+=($!)

    labels+=("nixos ${host} eval:$local_nixos_out" "home ${host} eval:$local_home_out")
  done

  # Wait for all background jobs, propagating any failures
  fail=0
  for pid in "${pids[@]}"; do
    wait "$pid" || fail=1
  done

  # Print results in host order
  for entry in "${labels[@]}"; do
    cat "${entry#*:}"
  done

  if ((fail)); then
    exit 1
  fi
fi

if [[ "$TARGET" == "all" ]]; then
  run_step "flake check --no-build" \
    nix flake check --no-build --quiet "$FLAKE_REF"
else
  echo "flake check --no-build                       skipped (target mode)"
fi

echo "== Evaluation audit complete =="
