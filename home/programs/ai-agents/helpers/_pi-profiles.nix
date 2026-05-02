# Pi (badlogic/pi-mono) profile definitions: single source of truth for profile names
# and their provider/model overrides.
#
# Pi uses PI_CODING_AGENT_DIR to switch config directories, each with its own
# config.yml and models.yml.

{ config }:

let
  models = import ./_models.nix;
  profiles = [
    {
      name = "pi";
      provider = "zai";
      model = models.glm-raw;
      alias = "pi";
      contextWindow = 204800;
      thinkingLevel = "high";
      zaiKey = true;
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
      model = models.zen-pi;
      alias = "pizen";
      contextWindow = 1048576;
    }
  ];

  zaiProfiles = builtins.filter (p: p.zaiKey or false) profiles;
  zaiProfileNames = map (p: p.name) zaiProfiles;

  names = map (p: p.name) profiles;
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
