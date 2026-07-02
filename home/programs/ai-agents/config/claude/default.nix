# Claude Code configuration: permissions, lifecycle hooks, and extra settings.

_:

let
  claudePermissionRules = import ./_permission-rules.nix;
  claudeHooks = import ./_hooks.nix;
in
{
  programs.aiAgents = {
    claude = {
      enable = true;
      model = "opus";

      env = {
        EDITOR = "nvim";
        CLAUDE_CODE_MAX_OUTPUT_TOKENS = "32000";
        API_TIMEOUT_MS = "120000";
      };

      permissions = claudePermissionRules;
      hooks = claudeHooks;

      # === Extra Settings ===
      extraSettings = {
        cleanupPeriodDays = 14;
        respectGitignore = true;
        defaultMode = "bypassPermissions";
        skipDangerousModePermissionPrompt = true;
        alwaysThinkingEnabled = true;
        autoMemoryEnabled = true;
        enableAllProjectMcpServers = true;
        includeGitInstructions = false;
        autoUpdatesChannel = "latest";
        attribution = {
          commit = "";
          pr = "";
        };
      };
    };
  };
}
