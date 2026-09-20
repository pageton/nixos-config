# Antigravity CLI (agy) settings.
#
# agy reads native settings from ~/.gemini/antigravity-cli/settings.json and
# MCP servers from ~/.gemini/config/mcp_config.json. Both files are jq-merged
# at activation (activation/antigravity-setup.nix) so app-owned keys
# (trustedWorkspaces, colorScheme) survive. The legacy Gemini CLI layout
# (~/.gemini/settings.json) is no longer read by agy.

_:

let
  destructiveRules = import ../../helpers/_destructive-rules.nix;
in
{
  programs.aiAgents.antigravity = {
    enable = true;

    extraSettings = {
      # Full autonomy, consistent with the other agents. permissions.deny below
      # still blocks destructive commands (Deny > Ask > Allow).
      toolPermission = "always-proceed";
      artifactReviewPolicy = "always-proceed";
      # nsjail is not installed; leave terminal sandboxing off until it is.
      enableTerminalSandbox = false;
      allowNonWorkspaceAccess = false;
      editorMode = "vim";
      notifications = true;
      enableTelemetry = false;
      showTips = false;

      permissions.deny = destructiveRules.mkAntigravityDenyRules (
        destructiveRules.systemCommands ++ destructiveRules.gitCommands
      );
    };
  };
}
