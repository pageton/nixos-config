# Shared Oh My Pi (omp) profile definitions: single source of truth for profile names
# and their provider/model overrides. Adding a new profile only requires editing this file.
#
# Oh My Pi uses PI_CODING_AGENT_DIR to switch config directories, each with its own
# config.yml and models.yml. This mirrors the OPENCODE_CONFIG_DIR pattern.

{ config }:

let
  models = import ./_models.nix;
  profiles = [
    {
      name = "omp";
      provider = "zai";
      model = models.glm-raw;
      alias = "omp";
      contextWindow = 204800;
      thinkingLevel = "high";
      zaiKey = true;
    }
    {
      name = "omp-sonnet";
      provider = "anthropic";
      model = models.claude-sonnet-raw;
      alias = "omps";
      contextWindow = 200000;
    }
    {
      name = "omp-opus";
      provider = "anthropic";
      model = models.claude-opus-raw;
      alias = "ompop";
      contextWindow = 200000;
    }
    {
      name = "omp-glm";
      provider = "zai";
      model = models.glm-raw;
      alias = "ompglm";
      contextWindow = 204800;
      thinkingLevel = "high";
      zaiKey = true;
    }
    {
      name = "omp-gemini";
      provider = "google";
      model = models.gemini-raw;
      alias = "ompgem";
      contextWindow = 1048576;
    }
    {
      name = "omp-gpt";
      provider = "openai";
      model = models.gpt-default-raw;
      alias = "ompgpt";
      contextWindow = 128000;
    }
    {
      name = "omp-openrouter";
      provider = "openrouter";
      model = models.openrouter-raw;
      alias = "ompor";
      contextWindow = 200000;
    }
    {
      name = "omp-zen";
      provider = "opencode-zen";
      model = models.zen-raw;
      alias = "ompzen";
      contextWindow = 1048576;
    }
  ];

  zaiProfiles = builtins.filter (p: p.zaiKey or false) profiles;
  zaiProfileNames = map (p: p.name) zaiProfiles;

  names = map (p: p.name) profiles;
  # Oh My Pi profiles live under ~/.omp/profiles/<name>/
  # Each gets its own config.yml and models.yml.
  # The PI_CODING_AGENT_DIR env var switches between them.
  basePath = name: "${config.home.homeDirectory}/.omp/profiles/${name}";
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
