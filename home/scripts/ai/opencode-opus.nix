{ pkgs, ... }:
pkgs.writeShellScriptBin "opencode-opus" ''
  # opencode-opus - Run OpenCode with Claude Opus 4.6 for all agents
  set -euo pipefail

  CONFIG_FILE="$HOME/.config/opencode/oh-my-opencode.json"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    exec opencode --model anthropic/claude-opus-4-6 "$@"
  fi

  # Resolve symlink to get the real (nix store) path for restore
  ORIGINAL=$(readlink -f "$CONFIG_FILE")

  # Remove symlink and write patched copy
  rm -f "$CONFIG_FILE"
  ${pkgs.jq}/bin/jq '
    .agents.sisyphus.model = "anthropic/claude-opus-4-6" |
    .agents.sisyphus.variant = "max" |
    .agents.librarian.model = "anthropic/claude-opus-4-6" |
    .agents.librarian.variant = "max" |
    .agents.explore.model = "anthropic/claude-opus-4-6" |
    .agents.explore.variant = "max" |
    .agents.oracle.model = "anthropic/claude-opus-4-6" |
    .agents.oracle.variant = "max" |
    .agents["frontend-ui-ux-engineer"].model = "anthropic/claude-opus-4-6" |
    .agents["frontend-ui-ux-engineer"].variant = "max" |
    .agents["document-writer"].model = "anthropic/claude-opus-4-6" |
    .agents["document-writer"].variant = "max" |
    .agents["multimodal-looker"].model = "anthropic/claude-opus-4-6" |
    .agents["multimodal-looker"].variant = "max" |
    .agents.prometheus.model = "anthropic/claude-opus-4-6" |
    .agents.prometheus.variant = "max" |
    .agents.metis.model = "anthropic/claude-opus-4-6" |
    .agents.metis.variant = "max" |
    .agents.momus.model = "anthropic/claude-opus-4-6" |
    .agents.momus.variant = "max" |
    .agents.atlas.model = "anthropic/claude-opus-4-6" |
    .agents.atlas.variant = "max" |
    .categories["visual-engineering"].model = "anthropic/claude-opus-4-6" |
    .categories["visual-engineering"].variant = "max" |
    .categories.ultrabrain.model = "anthropic/claude-opus-4-6" |
    .categories.ultrabrain.variant = "max" |
    .categories.artistry.model = "anthropic/claude-opus-4-6" |
    .categories.artistry.variant = "max" |
    .categories.quick.model = "anthropic/claude-opus-4-6" |
    .categories.quick.variant = "max" |
    .categories["unspecified-low"].model = "anthropic/claude-opus-4-6" |
    .categories["unspecified-low"].variant = "max" |
    .categories["unspecified-high"].model = "anthropic/claude-opus-4-6" |
    .categories["unspecified-high"].variant = "max" |
    .categories.writing.model = "anthropic/claude-opus-4-6" |
    .categories.writing.variant = "max"
  ' "$ORIGINAL" > "$CONFIG_FILE"

  # Restore symlink on exit
  cleanup() { rm -f "$CONFIG_FILE"; ln -sf "$ORIGINAL" "$CONFIG_FILE"; }
  trap cleanup EXIT INT TERM

  # Run opencode
  opencode --model anthropic/claude-opus-4-6 "$@"
''
