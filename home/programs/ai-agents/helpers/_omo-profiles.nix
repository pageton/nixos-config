# Oh My OpenAgent (omo) profile definitions: OpenCode + oh-my-openagent plugin.
#
# Each profile gets its own XDG config directory with:
#   - opencode.json (base settings + oh-my-openagent plugin + model override)
#   - oh-my-openagent.json (omo agent model overrides)
#   - tui.json (theme)
#
# The `oco` alias prefix = opencode + omo. Adding a new profile only requires
# editing this file.

{ config }:

let
  models = import ./_models.nix;

  profiles = [
    {
      name = "opencode-omo-glm";
      model = models.glm;
      alias = "ocoglm";
    }
    {
      name = "opencode-omo-gemini";
      model = models.gemini;
      alias = "ocogem";
    }
    {
      name = "opencode-omo-gpt";
      model = models.gpt-default;
      alias = "ocogpt";
    }
    {
      name = "opencode-omo-openrouter";
      model = models.openrouter;
      alias = "ocoor";
    }
    {
      name = "opencode-omo-sonnet";
      model = models.claude-sonnet;
      alias = "ocos";
    }
    {
      name = "opencode-omo-zen";
      model = models.zen;
      alias = "ocozen";
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
