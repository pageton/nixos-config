# Pi settings.json builder: generates configuration per profile.
#
# Pi uses JSON settings files with project settings overriding global settings.
# Each profile gets its own directory under ~/.pi/profiles/<name>/
# with settings.json, models.json, and auth.json.

{
  cfg,
  config,
  lib,
}:

let
  piProfiles = import ./_pi-profiles.nix { inherit config; };
  globalInstructions = cfg.globalInstructions;

  # Base settings shared across all pi profiles.
  piBaseSettings =
    let
      inherit (cfg.pi)
        theme
        compaction
        retry
        extensions
        skills
        packages
        ;
    in
    {
      defaultThinkingLevel = cfg.pi.thinkingLevel;
      inherit
        theme
        compaction
        retry
        extensions
        skills
        packages
        ;
      quietStartup = false;
      enableSkillCommands = true;
    }
    // (lib.optionalAttrs (cfg.pi.sessionDir != "") { sessionDir = cfg.pi.sessionDir; })
    // (lib.optionalAttrs (cfg.pi.enabledModels != [ ]) { enabledModels = cfg.pi.enabledModels; })
    // (lib.optionalAttrs (cfg.pi.extraSettings != { }) cfg.pi.extraSettings);

  # Generate settings.json for a specific profile (provider + model override).
  mkPiSettings =
    {
      provider,
      model,
      thinkingLevel ? null,
      ...
    }:
    piBaseSettings
    // {
      defaultProvider = provider;
      defaultModel = model;
    }
    // (lib.optionalAttrs (thinkingLevel != null) { defaultThinkingLevel = thinkingLevel; });

  # All profile settings, keyed by profile name.
  piSettingsByProfile = builtins.listToAttrs (
    map (profile: {
      inherit (profile) name;
      value = mkPiSettings profile;
    }) piProfiles.profiles
  );

  # Generate models.json for a profile.
  # Adds custom providers (Z.AI proxy) where needed.
  mkPiModels =
    {
      provider,
      model,
      contextWindow ? 128000,
      zaiKey ? false,
      ...
    }:
    let
      # Z.AI provider entry — uses Anthropic Messages API compatibility.
      # NOTE: apiKey intentionally omitted here. Auth is handled by auth.json
      # which supports !command syntax (resolveConfigValue). models.json's
      # apiKey field does NOT resolve shell commands — only auth.json does.
      zaiProvider = {
        baseUrl = "__ZAI_API_ROOT__/anthropic";
        api = "anthropic-messages";
        models = [
          {
            id = model;
            reasoning = true;
            input = [
              "text"
              "image"
            ];
            inherit contextWindow;
          }
        ];
      };
      # OpenRouter provider entry.
      openrouterProvider = {
        baseUrl = "https://openrouter.ai/api/v1";
        api = "openai-completions";
        apiKey = "__OPENROUTER_API_KEY_PLACEHOLDER__";
        models = [
          {
            id = model;
            reasoning = true;
            input = [
              "text"
              "image"
            ];
            inherit contextWindow;
          }
        ];
      };
      # MiniMax provider entry (free tier via opencode).
      minimaxProvider = {
        baseUrl = "https://api.minimaxi.chat/v1";
        api = "openai-completions";
        apiKey = "__MINIMAX_API_KEY_PLACEHOLDER__";
        compat = {
          supportsDeveloperRole = false;
          supportsReasoningEffort = false;
        };
        models = [
          {
            id = model;
            input = [ "text" ];
            inherit contextWindow;
          }
        ];
      };
    in
    {
      providers =
        if provider == "zai" then
          { } # Pi has native ZAI support — no custom provider needed.
        else if provider == "openrouter" then
          { openrouter = openrouterProvider; }
        else if provider == "minimax" then
          { minimax = minimaxProvider; }
        else
          { };
    };

  # All profile models.json, keyed by profile name.
  piModelsByProfile = builtins.listToAttrs (
    map (profile: {
      inherit (profile) name;
      value = mkPiModels profile;
    }) piProfiles.profiles
  );

  # Generate auth.json for a profile.
  # Uses shell command resolution (!command) to read secrets at runtime.
  mkPiAuth =
    {
      provider,
      zaiKey ? false,
      ...
    }:
    let
      # Base auth entries — pi resolves keys from env vars for built-in providers.
      entries =
        { }
        # Anthropic: use env var or existing auth.
        // (lib.optionalAttrs (provider == "anthropic") {
          anthropic = {
            type = "api_key";
            key = "ANTHROPIC_API_KEY";
          };
        })
        # Google: use env var.
        // (lib.optionalAttrs (provider == "google") {
          google = {
            type = "api_key";
            key = "GEMINI_API_KEY";
          };
        })
        # OpenAI: use env var.
        // (lib.optionalAttrs (provider == "openai") {
          openai = {
            type = "api_key";
            key = "OPENAI_API_KEY";
          };
        })
        # Z.AI: shell command to read secret.
        // (lib.optionalAttrs zaiKey {
          zai = {
            type = "api_key";
            key = "!cat ${cfg.secrets.zaiApiKeyFile}";
          };
        });
    in
    entries;

  # All profile auth.json, keyed by profile name.
  piAuthByProfile = builtins.listToAttrs (
    map (profile: {
      inherit (profile) name;
      value = mkPiAuth profile;
    }) piProfiles.profiles
  );
in
{
  inherit piSettingsByProfile piModelsByProfile piAuthByProfile;
}
