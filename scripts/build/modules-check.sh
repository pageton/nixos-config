#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

error_count=0

mapfile -t defaults < <(find . -type f -name default.nix)

for default in "${defaults[@]}"; do
  dir=$(dirname "$default")
  printf 'Checking %s\n' "$default" >&2

  pushd "$dir" >/dev/null

  mapfile -t imported < <(
    grep -oE '(\./|\.\./)[^ ]+\.nix' default.nix
  )

  has_nested_modules=0
  if grep -oE '\./[^ ]+' default.nix | grep -vqE '\.nix$'; then
    has_nested_modules=1
  fi

  declare -A imp=()
  declare -A import_paths=()
  for m in "${imported[@]}"; do
    if [[ "$m" == ./* ]]; then
      imp["${m#./}"]=1
    fi
    import_paths["$m"]=1
  done

  mapfile -t locals < <(
    find . -maxdepth 1 -type f -name '*.nix' \
      ! -name '_*.nix' \
      ! -name default.nix -printf '%f\n'
  )

  if ((has_nested_modules == 0)); then
    for f in "${locals[@]}"; do
      if [[ -z "${imp[$f]:-}" ]]; then
        printf 'Missing import: %s/%s\n' "$dir" "$f" >&2
        ((error_count++))
      fi
    done
  fi

  for m in "${!import_paths[@]}"; do
    if [[ ! -f $m ]]; then
      printf 'Bad import (no such file): %s/%s\n' "$dir" "$m" >&2
      ((error_count++))
    fi
  done

  popd >/dev/null
done

if ((error_count > 0)); then
  printf 'Found %d import error(s).\n' "$error_count" >&2
  exit 1
fi

printf 'All imports OK.\n' >&2
