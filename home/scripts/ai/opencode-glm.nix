{ pkgs, ... }:
pkgs.writeShellScriptBin "opencode-glm" ''
  # opencode-glm - Run OpenCode with the dedicated GLM profile.
  set -euo pipefail

  OPENCODE_CONFIG_DIR="$HOME/.config/opencode-glm" \
    exec opencode --model zai-coding-plan/glm-5.1 "$@"
''
