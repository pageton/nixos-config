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
  ompProfiles = import ./_omp-profiles.nix { inherit config; };

  # Helper to convert Nix attrs to YAML string.
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
              map (e: "${indent depth}${e.k}:${serialize e.valAt (depth + 1)}") entries
            )
        else if builtins.isList v then
          if v == [ ] then
            " []"
          else
            "\n"
            + builtins.concatStringsSep "\n" (map (item: "${indent depth}-${serialize item (depth + 1)}") v)
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
  ompBaseSettings =
    let
      inherit (cfg.omp)
        compaction
        retry
        extensions
        skills
        packages
        ;
    in
    {
      defaultThinkingLevel = cfg.omp.thinkingLevel;
      collapseChangelog = true;
      inherit compaction retry;
    }
    // (lib.optionalAttrs (extensions != [ ]) { inherit extensions; })
    // (lib.optionalAttrs (skills != [ ]) { inherit skills; })
    // (lib.optionalAttrs (packages != [ ]) { inherit packages; })
    // (lib.optionalAttrs (cfg.omp.theme != "") { theme = cfg.omp.theme; })
    // (lib.optionalAttrs (cfg.omp.sessionDir != "") { sessionDir = cfg.omp.sessionDir; })
    // (lib.optionalAttrs (cfg.omp.enabledModels != [ ]) { enabledModels = cfg.omp.enabledModels; });

  mkOmpConfig =
    {
      provider,
      model,
      thinkingLevel ? null,
      ...
    }:
    ompBaseSettings
    // {
      defaultProvider = provider;
      defaultModel = model;
    }
    // (lib.optionalAttrs (thinkingLevel != null) { defaultThinkingLevel = thinkingLevel; });

  ompConfigsByProfile = builtins.listToAttrs (
    map (profile: {
      inherit (profile) name;
      value = toYaml (mkOmpConfig profile);
    }) ompProfiles.profiles
  );

  mkOmpModels =
    {
      provider,
      model,
      contextWindow ? 128000,
      zaiKey ? false,
      ...
    }:
    let
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

  ompModelsByProfile = builtins.listToAttrs (
    map (profile: {
      inherit (profile) name;
      value = mkOmpModels profile;
    }) ompProfiles.profiles
  );
in
{
  inherit ompConfigsByProfile ompModelsByProfile;
}
