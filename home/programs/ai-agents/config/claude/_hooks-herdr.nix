# herdr agent session hook for Claude Code.
# Reports the active Claude session identity to herdr's socket API on session
# start so herdr can restore it and track working/idle state via PTY monitoring.
#
# herdr v0.7.0 (HERDR_INTEGRATION_VERSION=6) replaced the previous state-based
# hook model (working/blocked/idle/release on every event) with a single
# SessionStart hook that reports the session id + transcript path. Working/idle
# state is now derived from pane process monitoring, not hooks.
{ }:
let
  herdrHookScript = "$HOME/.claude/hooks/herdr-agent-state.sh";
in
{
  SessionStart = [
    {
      matcher = "*";
      hooks = [
        {
          type = "command";
          command = "${herdrHookScript} session";
          timeout = 10;
        }
      ];
    }
  ];
}
