# Per-agent settings builders and profile variant overrides.

{
  cfg,
  config,
  lib,
}:

let
  mcpTransforms = import ./_mcp-transforms.nix { inherit cfg lib; };
  formatterRegistry = import ./_formatters.nix;
  opencodeProfiles = import ./_opencode-profiles.nix { inherit config; };
  forgeProfiles = import ./_forge-profiles.nix { inherit config; };
  inherit (mcpTransforms) opencodeMcpServers geminiMcpServers forgeMcpServers;
  opencodeFormatterSettings = builtins.listToAttrs (
    map (formatter: {
      name = formatter.tool;
      value = {
        command = lib.splitString " " formatter.command;
        inherit (formatter) extensions;
      };
    }) formatterRegistry.formatters
  );

  mkOptionalOpencodeSetting =
    key: value:
    if builtins.isAttrs value then
      lib.optionalAttrs (value != { }) { ${key} = value; }
    else if builtins.isList value then
      lib.optionalAttrs (value != [ ]) { ${key} = value; }
    else
      lib.optionalAttrs (value != null) { ${key} = value; };

  claudeSettings = {
    inherit (cfg.claude) model permissions hooks;
    env =
      cfg.claude.env
      // (lib.optionalAttrs cfg.logging.enableOtel {
        CLAUDE_CODE_ENABLE_TELEMETRY = "1";
        OTEL_METRICS_EXPORTER = cfg.logging.otelExporter;
        OTEL_EXPORTER_OTLP_ENDPOINT = cfg.logging.otelEndpoint;
      });
  }
  // (lib.optionalAttrs (cfg.claude.extraSettings != { }) cfg.claude.extraSettings);

  opencodeSettings = {
    "$schema" = "https://opencode.ai/config.json";
    inherit (cfg.opencode) model;
    mcp = opencodeMcpServers;
    plugin = cfg.opencode.plugins;
    provider = cfg.opencode.providers;
    # Disable snapshot system to prevent tmp_pack_* file leaks and disk bloat (#14811)
    snapshot = false;
    watcher.ignore = [
      "node_modules/**"
      "dist/**"
      ".git/**"
      ".venv/**"
      "target/**"
      "build/**"
      "coverage/**"
      "__pycache__/**"
      ".next/**"
      "result/**"
    ];
  }
  // (mkOptionalOpencodeSetting "permission" cfg.opencode.permission)
  // (mkOptionalOpencodeSetting "agent" cfg.opencode.agent)
  // (mkOptionalOpencodeSetting "command" cfg.opencode.command)
  // (mkOptionalOpencodeSetting "lsp" cfg.opencode.lsp)
  // (mkOptionalOpencodeSetting "formatter" (
    if cfg.opencode.formatter == { } then opencodeFormatterSettings else cfg.opencode.formatter
  ))
  // (mkOptionalOpencodeSetting "experimental" cfg.opencode.experimental)
  // (mkOptionalOpencodeSetting "default_agent" cfg.opencode.defaultAgent)
  // (mkOptionalOpencodeSetting "enabled_providers" cfg.opencode.enabledProviders)
  // (mkOptionalOpencodeSetting "disabled_providers" cfg.opencode.disabledProviders)
  // (lib.optionalAttrs (cfg.globalInstructions != "") { instructions = [ cfg.globalInstructions ]; })
  // (lib.optionalAttrs (cfg.opencode.extraSettings != { }) cfg.opencode.extraSettings);

  geminiSettings = {
    mcpServers = geminiMcpServers;
  }
  // (lib.optionalAttrs (cfg.globalInstructions != "") {
    systemInstruction = cfg.globalInstructions;
  })
  // (lib.optionalAttrs (cfg.gemini.extraSettings != { }) cfg.gemini.extraSettings);

  # Derived from _opencode-profiles.nix — single source of truth for profile→model mapping.
  opencodeSettingsByProfile = builtins.listToAttrs (
    map (
      { name, model, ... }:
      {
        inherit name;
        value = if model == null then opencodeSettings else opencodeSettings // { inherit model; };
      }
    ) opencodeProfiles.profiles
  );

  # Forge TOML config generation per profile.
  # Forge uses TOML with [session] provider_id/model_id for model selection.
  mkForgeToml =
    { provider_id, model_id, ... }:
    let
      inherit (cfg.forge) reasoningEffort maxTokens;
      globalInstructions = cfg.globalInstructions;
    in
    ''
      "$schema" = "https://forgecode.dev/schema.json"

      max_tokens = ${toString maxTokens}
      verify_todos = true
      research_subagent = true
      subagents = true

      [session]
      provider_id = "${provider_id}"
      model_id = "${model_id}"

      [reasoning]
      enabled = true
      effort = "${reasoningEffort}"

      [compact]
      eviction_window = 0.2
      max_tokens = 2000
      message_threshold = 200
      on_turn_end = false
      retention_window = 6
      token_threshold = 100000

      [retry]
      backoff_factor = 2
      initial_backoff_ms = 200
      max_attempts = 8
      min_delay_ms = 1000
      suppress_errors = false

      [http]
      connect_timeout_secs = 30
      read_timeout_secs = 900

      [updates]
      auto_update = false
      frequency = "daily"
    ''
    + (lib.optionalString (globalInstructions != "") ''

      # Global instructions are loaded via AGENTS.md in the forge config directory.
    '')
    + (lib.optionalString (cfg.forge.extraToml != "") "\n${cfg.forge.extraToml}");

  forgeTomlByProfile = builtins.listToAttrs (
    map (profile: {
      inherit (profile) name;
      value = mkForgeToml profile;
    }) forgeProfiles.profiles
  );

  # Forge MCP config uses the same JSON format as Claude (.mcp.json with mcpServers key).
  forgeMcpJson = {
    mcpServers = forgeMcpServers;
  };
in
{
  inherit
    claudeSettings
    opencodeSettings
    geminiSettings
    opencodeSettingsByProfile
    forgeTomlByProfile
    forgeMcpJson
    ;
}
