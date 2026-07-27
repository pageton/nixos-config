# Codex CLI system-level configuration — managed hooks via requirements.toml.
# Managed hooks are trusted by policy and don't require user review.
#
# The herdr SessionStart hook reports the active Codex session to herdr's
# socket API so herdr can track working/idle state via PTY monitoring.
# The hook script itself is deployed by home-manager at
# ~/.codex/herdr-agent-state.sh and exits cleanly (0) when herdr isn't running.
{ config, lib, ... }:
let
  cfg = config.mySystem.codex;
in
{
  options.mySystem.codex = {
    enable = lib.mkEnableOption "Codex CLI system-level managed hooks";
  };

  config = lib.mkIf cfg.enable {
    environment.etc."codex/requirements.toml" = {
      text = ''
        [[hooks.SessionStart]]
        matcher = "startup|resume"

        [[hooks.SessionStart.hooks]]
        type = "command"
        command = "$HOME/.codex/herdr-agent-state.sh session"
        timeout = 10
      '';
      mode = "0444";
    };
  };
}
