# Shared OpenCode profile definitions: single source of truth for profile names
# and their model overrides. Adding a new profile only requires editing this file.

{ config }:

let
  models = import ./_models.nix;

  profiles = [
    {
      name = "opencode";
      model = null;
      alias = "oc";
    }
    {
      name = "opencode-glm";
      model = models.glm;
      alias = "ocglm";
    }
    {
      name = "opencode-gemini";
      model = models.gemini;
      alias = "ocgem";
    }
    {
      name = "opencode-gpt";
      model = models.gpt-default;
      alias = "ocgpt";
    }
    {
      name = "opencode-openrouter";
      model = models.openrouter;
      alias = "ocor";
    }
    {
      name = "opencode-sonnet";
      model = models.claude-sonnet;
      alias = "ocs";
    }
    {
      name = "opencode-zen";
      model = models.zen;
      alias = "oczen";
    }
    {
      name = "opencode-sisyphus";
      model = models."kimi-k2.5";
      alias = "ocsis";
    }
    {
      name = "opencode-hephaestus";
      model = models."gpt-5.4";
      alias = "ochep";
    }
    {
      name = "opencode-prometheus";
      model = models.claude-opus;
      alias = "ocpro";
    }
    {
      name = "opencode-atlas";
      model = models.claude-sonnet;
      alias = "ocatl";
    }
    {
      name = "opencode-oracle";
      model = models."gpt-5.4";
      alias = "ocora";
    }
    {
      name = "opencode-librarian";
      model = models."minimax-m2.7";
      alias = "oclib";
    }
    {
      name = "opencode-explore";
      model = models.grok-code-fast-1;
      alias = "ocexp";
    }
    {
      name = "opencode-metis";
      model = models.claude-opus;
      alias = "ocmet";
    }
    {
      name = "opencode-momus";
      model = models."gpt-5.4";
      alias = "ocmom";
    }
    {
      name = "opencode-multimodal";
      model = models."gpt-5.4";
      alias = "ocmulti";
    }
  ];

  names = map (p: p.name) profiles;
  configPath = name: "${config.xdg.configHome}/${name}/opencode.json";
in
{
  inherit
    names
    configPath
    profiles
    ;
}
