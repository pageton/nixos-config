{ pkgs, ... }:
pkgs.writeShellScriptBin "opencode-glm" ''
  # opencode-glm - Run OpenCode with GLM for all agents
  set -euo pipefail

  CONFIG_FILE="$HOME/.config/opencode/oh-my-opencode.json"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    exec opencode --model zai-coding-plan/glm-5 "$@"
  fi

  # Resolve symlink to get the real (nix store) path for restore
  ORIGINAL=$(readlink -f "$CONFIG_FILE")

  # Remove symlink and write patched copy
  rm -f "$CONFIG_FILE"
  ${pkgs.jq}/bin/jq '
    .agents.sisyphus.model = "zai-coding-plan/glm-5" |
    del(.agents.sisyphus.variant) |
    .agents.librarian.model = "zai-coding-plan/glm-5" |
    del(.agents.librarian.variant) |
    .agents.explore.model = "zai-coding-plan/glm-5" |
    del(.agents.explore.variant) |
    .agents.oracle.model = "zai-coding-plan/glm-5" |
    del(.agents.oracle.variant) |
    .agents["frontend-ui-ux-engineer"].model = "zai-coding-plan/glm-5" |
    del(.agents["frontend-ui-ux-engineer"].variant) |
    .agents["document-writer"].model = "zai-coding-plan/glm-5" |
    del(.agents["document-writer"].variant) |
    .agents["multimodal-looker"].model = "zai-coding-plan/glm-5" |
    del(.agents["multimodal-looker"].variant) |
    .agents.prometheus.model = "zai-coding-plan/glm-5" |
    del(.agents.prometheus.variant) |
    .agents.metis.model = "zai-coding-plan/glm-5" |
    del(.agents.metis.variant) |
    .agents.momus.model = "zai-coding-plan/glm-5" |
    del(.agents.momus.variant) |
    .agents.atlas.model = "zai-coding-plan/glm-5" |
    del(.agents.atlas.variant) |
    .categories["visual-engineering"].model = "zai-coding-plan/glm-5" |
    del(.categories["visual-engineering"].variant) |
    .categories.ultrabrain.model = "zai-coding-plan/glm-5" |
    del(.categories.ultrabrain.variant) |
    .categories.artistry.model = "zai-coding-plan/glm-5" |
    del(.categories.artistry.variant) |
    .categories.quick.model = "zai-coding-plan/glm-5" |
    del(.categories.quick.variant) |
    .categories["unspecified-low"].model = "zai-coding-plan/glm-5" |
    del(.categories["unspecified-low"].variant) |
    .categories["unspecified-high"].model = "zai-coding-plan/glm-5" |
    del(.categories["unspecified-high"].variant) |
    .categories.writing.model = "zai-coding-plan/glm-5" |
    del(.categories.writing.variant)
  ' "$ORIGINAL" > "$CONFIG_FILE"

  # Restore symlink on exit
  cleanup() { rm -f "$CONFIG_FILE"; ln -sf "$ORIGINAL" "$CONFIG_FILE"; }
  trap cleanup EXIT INT TERM

  # Run opencode
  opencode --model zai-coding-plan/glm-5 "$@"
''
