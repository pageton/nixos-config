#!/usr/bin/env bash
# Install skills from a GitHub repo into ~/.claude/skills/.
# Mirrors the install_repo_via_clone logic from activation/skills.nix.
set -euo pipefail

repo="${1:?Usage: skill-add.sh <owner/repo>}"
skills_dir="$HOME/.claude/skills"

tmp_dir="$(mktemp -d)"
cleanup() { rm -rf "$tmp_dir"; }
trap cleanup EXIT

if ! git clone --depth 1 "https://github.com/$repo" "$tmp_dir" 2>/dev/null; then
  echo "❌ Clone failed: $repo (repo may not exist)"
  exit 1
fi

found=0
for src in "$tmp_dir/skills" "$tmp_dir/.claude/skills"; do
  if [[ -d "$src" ]]; then
    cp -r "$src"/* "$skills_dir/" 2>/dev/null && found=1
  fi
done

# Fallback: find any SKILL.md and copy its parent dir
if [[ "$found" -eq 0 ]]; then
  while IFS= read -r skill_md; do
    cp -r "$(dirname "$skill_md")" "$skills_dir/" 2>/dev/null && found=1
  done < <(find "$tmp_dir" -name SKILL.md 2>/dev/null)
fi

if [[ "$found" -eq 1 ]]; then
  echo "✔ Installed $repo"
else
  echo "❌ No SKILL.md found in $repo"
  exit 1
fi
