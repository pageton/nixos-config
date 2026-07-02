# Home file and XDG config file declarations for AI agents.

{
  config,
  constants,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;

  herdrPkgVersion = config.programs.herdr.package.version;

  inherit (builtins) toJSON;

  fileTemplates = import ./helpers/_file-templates.nix;
  geminiPolicies = import ./helpers/_gemini-policies.nix;
  herdrMimoPlugin = import ./helpers/_herdr-mimo-plugin.nix;
  impeccable = import ./helpers/_impeccable-commands.nix;
  models = import ./helpers/_models.nix;
  agentEnvContent = import ./helpers/_agent-env.nix { inherit constants; };
  aliasLib = import ./helpers/_aliases.nix {
    inherit
      config
      constants
      lib
      pkgs
      ;
  };
  settingsBuilders = import ./helpers/_settings-builders.nix { inherit cfg config lib; };
  inherit (settingsBuilders)
    antigravitySettings
    opencodeSettingsByProfile
    opencodeAndroidReMcpServers
    opencodeWebReMcpServers
    mimoSettings
    ompSettings
    ;

  opencodeProfiles = import ./helpers/_opencode-profiles.nix { inherit config; };
  opencodeProfileNames = opencodeProfiles.names;
  opencodeConfigFiles = builtins.listToAttrs (
    lib.flatten (
      map (name: [
        {
          name = "${name}/opencode.json";
          value = {
            text = toJSON opencodeSettingsByProfile.${name};
            force = true;
          };
        }
        {
          name = "${name}/tui.json";
          value = {
            text = toJSON { theme = "catppuccin-macchiato"; };
            force = true;
          };
        }
      ]) opencodeProfileNames
    )
  );

  opencodeImpeccableCommandFiles =
    if cfg.impeccable.enable then
      builtins.listToAttrs (
        lib.flatten (
          map (
            profile:
            map (cmd: {
              name = "${profile}/commands/${cmd.name}.md";
              value = {
                text = impeccable.mkImpeccableCommandText cmd;
                force = true;
              };
            }) impeccable.impeccableCommandDefs
          ) opencodeProfileNames
        )
      )
    else
      { };

  mkTextFiles =
    prefix: templates:
    builtins.listToAttrs (
      lib.mapAttrsToList (name: text: {
        name = "${prefix}/${name}";
        value = { inherit text; };
      }) templates
    );
in
{
  config = lib.mkIf cfg.enable {
    home.file = lib.mkMerge [
      # === Claude Agent Definitions ===
      (lib.mkIf cfg.claude.enable (mkTextFiles ".claude/agents" fileTemplates.claudeAgents))

      # === agentmemory Bootstrap ===
      (lib.mkIf cfg.agentmemory.enable {
        ".agentmemory/preferences.json" = {
          text = toJSON {
            schemaVersion = 1;
            lastAgent = null;
            lastAgents = [ ];
            lastProvider = null;
            skipSplash = true;
            skipNpxHint = true;
            skipGlobalInstall = true;
            skipConsoleInstall = true;
            firstRunAt = "1970-01-01T00:00:00.000Z";
          };
          force = true;
        };
      })

      # === herdr Agent State Integrations ===
      (lib.mkIf cfg.herdr.enable {
        ".claude/hooks/herdr-agent-state.sh" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/ogulcancelik/herdr/v${herdrPkgVersion}/src/integration/assets/claude/herdr-agent-state.sh";
            sha256 = "sha256-/9Wna3xi9TEwQPwemPoBD/Gaeqhd2f5vMluXKdXwG0Y=";
          };
          executable = true;
          force = true;
        };
        ".codex/herdr-agent-state.sh" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/ogulcancelik/herdr/v${herdrPkgVersion}/src/integration/assets/codex/herdr-agent-state.sh";
            sha256 = "sha256-KsgRU1n/hJzWHkUFdLNx9nMngKY6B62HwARI21wgNi0=";
          };
          executable = true;
          force = true;
        };
        ".codex/hooks.json" = {
          text = toJSON {
            hooks = {
              SessionStart = [
                {
                  hooks = [
                    {
                      type = "command";
                      command = "~/.codex/herdr-agent-state.sh session";
                      timeout = 10;
                    }
                  ];
                }
              ];
            };
          };
          force = true;
        };
        ".copilot/herdr-agent-state.sh" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/ogulcancelik/herdr/v${herdrPkgVersion}/src/integration/assets/copilot/herdr-agent-state.sh";
            sha256 = "sha256-Lgl/11kpgPrzpVfTmTLi9Qi7OZl3I3Rx1cyDaXY+99A=";
          };
          executable = true;
          force = true;
        };
      })

      # === Aider Configuration (independent of any agent enable gate) ===
      {
        ".aider.conf.yml".text = builtins.toJSON {
          model = models.aider-model;
          editor-model = models.aider-editor;
          auto-commits = false;
          dirty-commits = false;
          attribute-author = false;
          attribute-committer = false;
          dark-mode = true;
          pretty = true;
          stream = true;
          map-tokens = 2048;
          map-refresh = "auto";
          auto-lint = true;
          lint-cmd = "just lint";
          auto-test = false;
          test-cmd = "just check";
          suggest-shell-commands = false;
        };
      }

      # === Antigravity Files (Settings, Commands, Policies) ===
      (lib.mkIf cfg.antigravity.enable (
        {
          ".gemini/settings.json" = {
            text = toJSON antigravitySettings;
            force = true;
          };
        }
        // (mkTextFiles ".gemini/commands" fileTemplates.antigravityCommands)
        // (mkTextFiles ".gemini/policies" geminiPolicies)
      ))

      # === Oh My Pi (omp): MCP config (~/.omp/agent/mcp.json) ===
      (lib.mkIf cfg.omp.enable {
        ".omp/agent/mcp.json" = {
          text = toJSON ompSettings;
          force = true;
        };
      })

      # === Oh My Pi (omp): herdr agent state extension ===
      (lib.mkIf (cfg.herdr.enable && cfg.omp.enable) {
        ".omp/agent/extensions/herdr-omp-agent-state.ts" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/ogulcancelik/herdr/v${herdrPkgVersion}/src/integration/assets/omp/herdr-agent-state.ts";
            sha256 = "sha256-2bdE/8Xr6+lOHrstuLXJJJ35eFhKBIYhhG/ZlXMkHOM=";
          };
          force = true;
        };
      })
    ];

    xdg.configFile = lib.mkMerge [
      # Runtime model/service config for shell scripts (always available when agents enabled)
      (lib.mkIf cfg.enable {
        "ai-agents/models.sh" = {
          text = agentEnvContent;
          force = true;
        };
        "ai-agents/aliases.sh" = {
          text = aliasLib.generatedBashRegistry;
          force = true;
        };
      })
      # Android RE agent-specific MCP server fragment (merged into runtime config by launcher)
      (lib.mkIf cfg.enable {
        "opencode/android-re-mcp-servers.json" = {
          text = toJSON opencodeAndroidReMcpServers;
          force = true;
        };
      })
      # Web RE agent-specific MCP server fragment (merged into runtime config by launcher)
      (lib.mkIf cfg.enable {
        "opencode/web-re-mcp-servers.json" = {
          text = toJSON opencodeWebReMcpServers;
          force = true;
        };
      })
      (lib.mkIf cfg.opencode.enable (opencodeConfigFiles // opencodeImpeccableCommandFiles))
      # MiMoCode config (MCP servers, shared with OpenCode format)
      (lib.mkIf cfg.enable {
        "mimocode/config.json" = {
          text = toJSON mimoSettings;
          force = true;
        };
      })
      # herdr agent state plugin for OpenCode (auto-discovered from plugins/ dir)
      (lib.mkIf (cfg.herdr.enable && cfg.opencode.enable) {
        "opencode/plugins/herdr-agent-state.js" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/ogulcancelik/herdr/v${herdrPkgVersion}/src/integration/assets/opencode/herdr-agent-state.js";
            sha256 = "sha256-izSbTnCsAcKciqgOyEAbgrlRGigWeKLFqj2++/jyTvo=";
          };
          force = true;
        };
      })
      # herdr agent state plugin for MiMoCode (same OpenCode plugin API, placed in mimo config dir)
      (lib.mkIf cfg.herdr.enable {
        "mimocode/plugins/herdr-agent-state.js" = {
          text = herdrMimoPlugin.pluginJs;
          force = true;
        };
      })
    ];
  };
}
