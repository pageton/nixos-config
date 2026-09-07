# herdr agent session hook for Claude Code.
# Reports the active Claude session identity to herdr's socket API on session
# start so herdr can restore it; working/idle/blocked state is derived from
# pane PTY + screen detection, not hooks.
#
# Registration mirrors herdr's canonical claude_settings.rs install (protocol
# v9): single SessionStart entry, matcher "*", timeout 10, command
# `bash '<abs-path>' session` — byte-exact so `herdr integration
# install/uninstall claude` recognizes it instead of duplicating it.
{
  homeDirectory ? null,
}:

let
  # Absolute when homeDirectory is known; $HOME shell expansion otherwise.
  herdrHookScript =
    if homeDirectory != null then
      "'${homeDirectory}/.claude/hooks/herdr-agent-state.sh'"
    else
      "\"\$HOME/.claude/hooks/herdr-agent-state.sh\"";
in
{
  SessionStart = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = "bash ${herdrHookScript} session";
          timeout = 10;
        }
      ];
    }
  ];
}
