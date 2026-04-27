# Shared Pi profile definitions: single source of truth for profile names
# and their provider/model overrides. Adding a new profile only requires editing this file.
#
# Pi uses PI_CODING_AGENT_DIR to switch config directories, each with its own
# settings.json, models.json, and auth.json. This mirrors the OPENCODE_CONFIG_DIR pattern.

{ config }:

let
  models = import ./_models.nix;
  profiles = [
    {
      name = "pi";
      provider = "anthropic";
      model = models.claude-sonnet-default;
      alias = "pi";
      contextWindow = 200000;
    }
    {
      name = "pi-sonnet";
      provider = "anthropic";
      model = models.claude-sonnet-raw;
      alias = "pis";
      contextWindow = 200000;
    }
    {
      name = "pi-opus";
      provider = "anthropic";
      model = models.claude-opus-raw;
      alias = "piop";
      contextWindow = 200000;
    }
    {
      name = "pi-glm";
      provider = "zai";
      model = models.glm-raw;
      alias = "piglm";
      contextWindow = 204800;
      thinkingLevel = "high";
      zaiKey = true;
    }
    {
      name = "pi-gemini";
      provider = "google";
      model = models.gemini-raw;
      alias = "pigem";
      contextWindow = 1048576;
    }
    {
      name = "pi-gpt";
      provider = "openai";
      model = models.gpt-default-raw;
      alias = "pigpt";
      contextWindow = 128000;
    }
    {
      name = "pi-openrouter";
      provider = "openrouter";
      model = models.openrouter-raw;
      alias = "pior";
      contextWindow = 200000;
    }
    {
      name = "pi-zen";
      provider = "minimax";
      model = models.zen-raw;
      alias = "pizen";
      contextWindow = 1048576;
    }
  ];

  zaiProfiles = builtins.filter (p: p.zaiKey or false) profiles;
  zaiProfileNames = map (p: p.name) zaiProfiles;

  names = map (p: p.name) profiles;
  # Pi profiles live under ~/.pi/profiles/<name>/
  # Each gets its own settings.json, models.json, auth.json.
  # The PI_CODING_AGENT_DIR env var switches between them.
  basePath = name: "${config.home.homeDirectory}/.pi/profiles/${name}";
in
{
  inherit
    names
    basePath
    profiles
    zaiProfiles
    zaiProfileNames
    ;
}
