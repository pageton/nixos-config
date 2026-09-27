# herdr GitHub Copilot CLI hook registration — idempotent merge into
# settings.json.
#
# Copilot's settings.json is app-owned (the CLI writes telemetry/preference
# state on first run), so a home.file declaration would be a read-only store
# symlink. Registration is an activation jq merge instead; a fresh file is
# written when Copilot has not created one yet (no migration constraint like
# OpenCode's cli.json, so no deferral).
#
# Mirrors `herdr integration install copilot` (protocol v3): a direct
# SessionStart command hook under the settings "hooks" object, command
# `bash '<abs-path>'` (no action), timeout 10 (timeoutSec in Copilot's
# direct-hook schema), no matcher. Existing entries matching the command
# (command/bash/powershell fields, like herdr's own matcher) are replaced by
# the canonical entry so `install` does not duplicate it.

{
  cfg,
  pkgs,
  lib,
}:
lib.mkIf cfg.herdr.enable (
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    copilot_cfg="$HOME/.copilot/settings.json"
    hook_path="$HOME/.copilot/hooks/herdr-agent-state.sh"

    # Older home-manager generations deployed the hook at ~/.copilot/ directly;
    # upstream expects ~/.copilot/hooks/ (status check) — drop the legacy file.
    legacy_hook="$HOME/.copilot/herdr-agent-state.sh"
    if [[ -f "$legacy_hook" ]] && grep -q 'HERDR_INTEGRATION_ID=copilot' "$legacy_hook"; then
      rm -f "$legacy_hook"
      echo "✓ Removed legacy herdr copilot hook (relocated to ~/.copilot/hooks/)"
    fi

    copilot_tmp="$(mktemp)"
    if [[ -f "$copilot_cfg" ]]; then
      if ${pkgs.jq}/bin/jq --arg cmd "bash '$hook_path'" '
        def is_herdr:
          (.type? == "command") and ((.command? // .bash? // .powershell? // "") == $cmd);
        if (.hooks | type) == "object" then
          .hooks.SessionStart = (
            if (.hooks.SessionStart | type) == "array" then
              [{ type: "command", bash: $cmd, timeoutSec: 10 }] +
              [.hooks.SessionStart[] | select(is_herdr | not)]
            else
              [{ type: "command", bash: $cmd, timeoutSec: 10 }]
            end
          )
        else
          .hooks = { SessionStart: [{ type: "command", bash: $cmd, timeoutSec: 10 }] }
        end
      ' "$copilot_cfg" > "$copilot_tmp" 2>/dev/null; then
        mv "$copilot_tmp" "$copilot_cfg"
        echo "✓ herdr Copilot SessionStart hook registered in settings.json"
      else
        rm -f "$copilot_tmp"
        echo "⚠ herdr Copilot registration skipped — settings.json is not plain JSON; add a SessionStart hook manually"
      fi
    else
      ${pkgs.jq}/bin/jq -n --arg cmd "bash '$hook_path'" \
        '{ hooks: { SessionStart: [{ type: "command", bash: $cmd, timeoutSec: 10 }] } }' \
        > "$copilot_cfg"
      echo "✓ herdr Copilot SessionStart hook written to settings.json"
    fi
  ''
)
