# Oh My Pi (omp) config.yml builder: generates configuration per profile.
#
# Oh My Pi uses YAML config files (config.yml) with automatic JSON→YAML migration.
# Each profile gets its own directory under ~/.omp/profiles/<name>/
# with config.yml and models.yml.
# Auth is managed via agent.db (SQLite) using `omp auth login` or env vars.

{
  cfg,
  config,
  lib,
  pkgs,
}:

let
  piProfiles = import ./_pi-profiles.nix { inherit config; };

  # Helper to convert Nix attrs to YAML string.
  # Uses nested attrset → YAML line format.
  toYaml =
    val:
    let
      indent = level: builtins.concatStringsSep "" (builtins.genList (_: "  ") level);
      serialize =
        v: depth:
        if builtins.isAttrs v then
          let
            entries = lib.mapAttrsToList (k: valAt: {
              inherit k valAt;
            }) v;
          in
          if entries == [ ] then
            "{}"
          else
            "\n"
            + builtins.concatStringsSep "\n" (
              map (
                e:
                "${indent depth}${e.k}:${serialize e.valAt (depth + 1)}"
              ) entries
            )
        else if builtins.isList v then
          if v == [ ] then
            " []"
          else
            "\n"
            + builtins.concatStringsSep "\n" (
              map (item: "${indent depth}-${serialize item (depth + 1)}") v
            )
        else if builtins.isBool v then
          " ${lib.boolToString v}"
        else if builtins.isInt v then
          " ${toString v}"
        else if builtins.isFloat v then
          " ${toString v}"
        else
          " \"${builtins.replaceStrings [ "\"" "\\" ] [ "\\\"" "\\\\" ] (toString v)}\"";
    in
    serialize val 0;

  # Base settings shared across all omp profiles.
  piBaseSettings =
    let
      inherit (cfg.pi)
        compaction
        retry
        extensions
        skills
        packages
        ;
    in
    {
      defaultThinkingLevel = cfg.pi.thinkingLevel;
      collapseChangelog = true;
      inherit compaction retry;
    }
    // (lib.optionalAttrs (extensions != [ ]) { inherit extensions; })
    // (lib.optionalAttrs (skills != [ ]) { inherit skills; })
    // (lib.optionalAttrs (packages != [ ]) { inherit packages; })
    // (lib.optionalAttrs (cfg.pi.theme != "") { theme = cfg.pi.theme; })
    // (lib.optionalAttrs (cfg.pi.sessionDir != "") { sessionDir = cfg.pi.sessionDir; })
    // (lib.optionalAttrs (cfg.pi.enabledModels != [ ]) { enabledModels = cfg.pi.enabledModels; });

  # Generate config.yml for a specific profile (provider + model override).
  mkOmpConfig =
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

  # All profile configs, keyed by profile name (YAML text).
  piConfigsByProfile = builtins.listToAttrs (
    map (profile: {
      inherit (profile) name;
      value = toYaml (mkOmpConfig profile);
    }) piProfiles.profiles
  );

  # Generate models.yml for a profile.
  # Adds custom providers (OpenRouter, MiniMax, etc.) where needed.
  mkOmpModels =
    {
      provider,
      model,
      contextWindow ? 128000,
      zaiKey ? false,
      ...
    }:
    let
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
      # MiniMax provider entry.
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
    if provider == "openrouter" then
      toYaml { providers.openrouter = openrouterProvider; }
    else if provider == "minimax" then
      toYaml { providers.minimax = minimaxProvider; }
    else
      "";

  # All profile models.yml, keyed by profile name.
  piModelsByProfile = builtins.listToAttrs (
    map (profile: {
      inherit (profile) name;
      value = mkOmpModels profile;
    }) piProfiles.profiles
  );
in
{
  inherit piConfigsByProfile piModelsByProfile;
}
