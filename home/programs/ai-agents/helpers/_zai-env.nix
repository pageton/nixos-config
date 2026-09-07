# Shared ZAI provider environment variables.
# Single source of truth for the env var block used by claude_glm (functions.nix)
# and Android RE launchers (android-re/_launchers.nix).
# The API key must be set separately by the caller (different loading mechanisms).

{ constants }:

let
  inherit (constants.services.zai) timeout;
  inherit (constants.services.zai.models) haiku sonnet opus;

  envVars = [
    {
      name = "ANTHROPIC_BASE_URL";
      value = "${constants.services.zai.apiRoot}/anthropic";
    }
    {
      name = "API_TIMEOUT_MS";
      value = toString timeout;
    }
    {
      name = "ANTHROPIC_DEFAULT_HAIKU_MODEL";
      value = haiku;
    }
    {
      name = "ANTHROPIC_DEFAULT_SONNET_MODEL";
      value = sonnet;
    }
    {
      name = "ANTHROPIC_DEFAULT_OPUS_MODEL";
      value = opus;
    }
    {
      # Required by Z.AI docs when using [1m] context models
      name = "CLAUDE_CODE_AUTO_COMPACT_WINDOW";
      value = "1000000";
    }
  ];
in
{
  inherit envVars;

  # Inline bash prefix: VAR=val \  (for inline env before a command)
  inlinePrefix = builtins.concatStringsSep " \\\n  " (map (v: "${v.name}=\"${v.value}\"") envVars);

  # Export block: export VAR=val\n (for script embedding)
  exportBlock = builtins.concatStringsSep "\n" (map (v: "export ${v.name}=\"${v.value}\"") envVars);
}
