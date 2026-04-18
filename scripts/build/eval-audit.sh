#!/usr/bin/env bash
set -euo pipefail

target="${1:-all}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

declare -a eval_labels=()
declare -a eval_attrs=()

max_jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)"
if (( max_jobs > 4 )); then
  max_jobs=4
elif (( max_jobs < 1 )); then
  max_jobs=1
fi

run_eval() {
  local label="$1"
  local attr="$2"

  echo "--- ${label} ---"
  time nix eval --raw "path:$PWD#${attr}.drvPath"
  echo ""
}

run_eval_async() {
  local label="$1"
  local attr="$2"
  local output_file="$3"

  (
    run_eval "$label" "$attr"
  ) >"${output_file}" 2>&1 &
}

queue_eval() {
  eval_labels+=("$1")
  eval_attrs+=("$2")
}

run_queued_evals() {
  local total="${#eval_labels[@]}"
  local start=0
  local exit_code=0

  while (( start < total )); do
    local -a batch_pids=()
    local -a batch_outputs=()
    local batch_count=0

    while (( start + batch_count < total && batch_count < max_jobs )); do
      local idx=$((start + batch_count))
      local output_file="${TMP_DIR}/eval-${idx}.log"

      batch_outputs+=("${output_file}")
      run_eval_async "${eval_labels[$idx]}" "${eval_attrs[$idx]}" "${output_file}"
      batch_pids+=("$!")
      ((batch_count += 1))
    done

    local batch_failed=0
    local pid
    for pid in "${batch_pids[@]}"; do
      if ! wait "$pid"; then
        batch_failed=1
      fi
    done

    local output_file
    for output_file in "${batch_outputs[@]}"; do
      cat "${output_file}"
    done

    if (( batch_failed )); then
      exit_code=1
    fi

    ((start += batch_count))
  done

  return "$exit_code"
}

list_attr_names() {
  local attr="$1"

  nix eval --raw "path:$PWD#${attr}" --apply '
    x: builtins.concatStringsSep "\n" (builtins.attrNames x)
  '
}

list_matching_home_configs() {
  local host="$1"

  nix eval --raw "path:$PWD#homeConfigurations" --apply "
    x:
      builtins.concatStringsSep \"\\n\" (
        builtins.filter (name: builtins.match \".*@${host}\" name != null) (builtins.attrNames x)
      )
  "
}

echo "=== Evaluation Audit (target: ${target}) ==="
echo ""

if [[ "$target" == "all" ]]; then
  mapfile -t nixos_hosts < <(list_attr_names "nixosConfigurations")
  for host in "${nixos_hosts[@]}"; do
    [[ -n "$host" ]] || continue
    queue_eval "nixosConfigurations.${host}" "nixosConfigurations.${host}.config.system.build.toplevel"
  done

  mapfile -t home_configs < <(list_attr_names "homeConfigurations")
  for home_cfg in "${home_configs[@]}"; do
    [[ -n "$home_cfg" ]] || continue
    queue_eval "homeConfigurations.${home_cfg}" "homeConfigurations.${home_cfg}.activationPackage"
  done
else
  queue_eval "nixosConfigurations.${target}" "nixosConfigurations.${target}.config.system.build.toplevel"

  mapfile -t matching_home_configs < <(list_matching_home_configs "$target")
  for home_cfg in "${matching_home_configs[@]}"; do
    [[ -n "$home_cfg" ]] || continue
    queue_eval "homeConfigurations.${home_cfg}" "homeConfigurations.${home_cfg}.activationPackage"
  done
fi

run_queued_evals

echo "Evaluation audit completed."
