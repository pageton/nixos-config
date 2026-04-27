# Shared Forge profile definitions: single source of truth for profile names
# and their provider/model overrides. Adding a new profile only requires editing this file.

{ config }:

let
  profiles = [
    {
      name = "forge";
      provider_id = "anthropic";
      model_id = "claude-opus-4-6";
      alias = "fg";
    }
    {
      name = "forge-glm";
      provider_id = "zai_coding";
      model_id = "glm-5.1";
      alias = "fgglm";
      zaiKey = true;
    }
    {
      name = "forge-gemini";
      provider_id = "google_ai_studio";
      model_id = "gemini-3-pro-preview";
      alias = "fggem";
    }
    {
      name = "forge-gpt";
      provider_id = "openai";
      model_id = "gpt-5.5";
      alias = "fggpt";
    }
    {
      name = "forge-openrouter";
      provider_id = "open_router";
      model_id = "openrouter/hunter-alpha";
      alias = "fgor";
    }
    {
      name = "forge-sonnet";
      provider_id = "anthropic";
      model_id = "claude-sonnet-4-6";
      alias = "fgs";
    }
    {
      name = "forge-zen";
      provider_id = "opencode_zen";
      model_id = "minimax-m2.5-free";
      alias = "fgzen";
    }
  ];

  zaiProfiles = builtins.filter (p: p.zaiKey or false) profiles;
  zaiProfileNames = map (p: p.name) zaiProfiles;

  names = map (p: p.name) profiles;
  basePath = name: "${config.home.homeDirectory}/.${name}";
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
