#!/usr/bin/env bash
set -euo pipefail

error_count=0

# 1) find all default.nix files
mapfile -t defaults < <(find . -type f -name default.nix)

for default in "${defaults[@]}"; do
  dir=$(dirname "$default")
  echo "⟳ Checking $default" >&2

  pushd "$dir" >/dev/null

  # 2) grab every "./*.nix" in the file and strip the "./"
  mapfile -t imported < <(
    grep -oE '\./[^ ]+\.nix' default.nix | sed 's#\./##'
  )

  # build a lookup set
  declare -A imp=()
  for m in "${imported[@]}"; do
    imp["$m"]=1
  done

  # 3) list all .nix files here except default.nix
  mapfile -t locals < <(
    find . -maxdepth 1 -type f -name '*.nix' \
      ! -name default.nix -printf '%f\n'
  )

  # 4a) any .nix on disk missing from imports?
  for f in "${locals[@]}"; do
    if [[ -z "${imp[$f]:-}" ]]; then
      echo "✗  Missing import: $dir/$f" >&2
      ((error_count++))
    fi
  done

  # 4b) any import pointing to a non-existent file?
  for m in "${imported[@]}"; do
    if [[ ! -f $m ]]; then
      echo "✗  Bad import (no such file): $dir/$m" >&2
      ((error_count++))
    fi
  done

  popd >/dev/null
done

if (( error_count > 0 )); then
  echo "➤ Found $error_count import error(s)." >&2
  exit 1
else
  echo "➤ All imports OK!" >&2
  exit 0
fi
