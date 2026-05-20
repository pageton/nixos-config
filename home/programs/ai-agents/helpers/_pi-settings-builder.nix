# Pi (badlogic/pi-mono) config.yml builder: generates configuration per profile.
#
# Pi uses YAML config files (config.yml). Each profile gets its own directory
# under ~/.pi/profiles/<name>/ with config.yml and models.yml.

{
  cfg,
  config,
  lib,
  ...
}:

let
  piProfiles = import ./_pi-profiles.nix { inherit config; };

  toYaml =
    val:
    let
      indent = level: builtins.concatStringsSep "" (builtins.genList (_: "  ") level);
      serialize =
        v: depth:
        if builtins.isAttrs v then
          let
            entries = lib.mapAttrsToList (k: valAt: { inherit k valAt; }) v;
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

  piBaseSettings =
    let
      inherit (cfg.pi) compaction retry skills;
    in
    {
      defaultThinkingLevel = cfg.pi.thinkingLevel;
      collapseChangelog = true;
      inherit compaction retry;
    }
    // (lib.optionalAttrs (skills != [ ]) { inherit skills; })
    // (lib.optionalAttrs (cfg.pi.theme != "") { theme = cfg.pi.theme; })
    // (lib.optionalAttrs (cfg.pi.sessionDir != "") { sessionDir = cfg.pi.sessionDir; })
    // (lib.optionalAttrs (cfg.pi.enabledModels != [ ]) { enabledModels = cfg.pi.enabledModels; });

  mkPiConfig =
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

  piConfigsByProfile = builtins.listToAttrs (
    map (profile: {
      inherit (profile) name;
      value = toYaml (mkPiConfig profile);
    }) piProfiles.profiles
  );

  mkPiModels =
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
    in
    if provider == "openrouter" then toYaml { providers.openrouter = openrouterProvider; } else "";

  piModelsByProfile = builtins.listToAttrs (
    map (profile: {
      inherit (profile) name;
      value = mkPiModels profile;
    }) piProfiles.profiles
  );
in
{
  inherit piConfigsByProfile piModelsByProfile;
}
