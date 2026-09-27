# Home file and XDG config file declarations for AI agents.

{
  config,
  constants,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;
  # herdr assets are fetched at the flake input's locked rev, not the version
  # tag: the input follows master, and release tags regularly lag the locked
  # rev's assets (v0.8.0 tag ships claude/codex v7 while the rev ships v8), so
  # tag URLs drift out of sync with the installed binary's expected versions.
  # Upstream repo lives at herdrdev/herdr (transferred from ogulcancelik).
  herdrAssetRev = inputs.herdr.rev;

  inherit (builtins) toJSON;

  fileTemplates = import ./helpers/_file-templates.nix;
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
    opencodeSettingsByProfile
    opencodeAndroidReMcpServers
    opencodeWebReMcpServers
    ompAndroidReMcpServers
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
            text = toJSON { theme = "catppuccin-mocha"; };
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

      # === herdr Agent State Integrations ===
      (lib.mkIf cfg.herdr.enable {
        ".claude/hooks/herdr-agent-state.sh" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/herdrdev/herdr/${herdrAssetRev}/src/integration/assets/claude/herdr-agent-state.sh";
            sha256 = "sha256-fxF8MD/8GmaXW3bdqBidcLcY/ASvTPfLEUSeTuW0roY=";
          };
          executable = true;
          force = true;
        };
        ".codex/herdr-agent-state.sh" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/herdrdev/herdr/${herdrAssetRev}/src/integration/assets/codex/herdr-agent-state.sh";
            sha256 = "sha256-OKkKKpmHLQbcvJeOdhNAbN2FLbsHUDq9ehE/UY1ZUfM=";
          };
          executable = true;
          force = true;
        };
        # herdr's copilot status check expects the hook under ~/.copilot/hooks/.
        # The SessionStart registration in settings.json is merged by activation
        # (herdr-copilot-setup.nix) since the app owns that file.
        ".copilot/hooks/herdr-agent-state.sh" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/herdrdev/herdr/${herdrAssetRev}/src/integration/assets/copilot/herdr-agent-state.sh";
            sha256 = "sha256-GXRg50I9JDhiaQ7rLa2qDursPULzEGxZckg7Apt5eCU=";
          };
          executable = true;
          force = true;
        };
      })

      # === herdr Antigravity CLI integration ===
      # Antigravity discovers global hooks from ~/.gemini/config: the hook
      # script plus its hooks.json registration under herdr's owned "herdr"
      # block. Byte-matches `herdr integration install antigravity-cli` output
      # (canonical command: bash '<abs-path>' session, timeout 10) so
      # `herdr integration status` reports it healthy.
      (lib.mkIf (cfg.herdr.enable && cfg.antigravity.enable) {
        ".gemini/config/hooks/herdr-agent-state.sh" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/herdrdev/herdr/${herdrAssetRev}/src/integration/assets/antigravity_cli/herdr-agent-state.sh";
            sha256 = "sha256-vfgHOiPeKqkZoj0ATBeI8q8wgkhKyxROL2c1aZmV7Ak=";
          };
          executable = true;
          force = true;
        };
        ".gemini/config/hooks.json" = {
          text = toJSON {
            PreInvocation = [
              {
                type = "command";
                command = "bash '${config.home.homeDirectory}/.gemini/config/hooks/herdr-agent-state.sh' session";
                timeout = 10;
              }
            ];
          };
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

      # Antigravity settings/commands/skills are written by activation
      # (activation/antigravity-setup.nix merges ~/.gemini/antigravity-cli/
      # settings.json; activation/skills.nix mirrors skills into
      # ~/.gemini/antigravity-cli/skills). The legacy Gemini layout
      # (~/.gemini/settings.json + .gemini/commands + .gemini/policies) is
      # no longer read by agy.

      # === Oh My Pi (omp): MCP config + global instructions (~/.omp/agent/) ===
      (lib.mkIf cfg.omp.enable (
        {
          ".omp/agent/mcp.json" = {
            text = toJSON ompSettings;
            force = true;
          };
        }
        // (lib.optionalAttrs (cfg.globalInstructions != "") {
          # omp native user context file — highest discovery priority, shadows
          # ~/.claude/CLAUDE.md etc. for omp sessions (same content, no loss).
          ".omp/agent/AGENTS.md" = {
            text = cfg.globalInstructions;
            force = true;
          };
        })
      ))

      # === Oh My Pi (omp): herdr agent state extension ===
      (lib.mkIf (cfg.herdr.enable && cfg.omp.enable) {
        ".omp/agent/extensions/herdr-omp-agent-state.ts" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/herdrdev/herdr/${herdrAssetRev}/src/integration/assets/omp/herdr-agent-state.ts";
            sha256 = "sha256-48ZQdSu5wuuLwe7MnOhFwnQ09rczGvFhNT3QbKbeSLc=";
          };
          force = true;
        };
      })

      # === ZCode: user-global instructions (~/.zcode/AGENTS.md) ===
      # ZCode reads user-global AGENTS.md at task start. The app owns
      # ~/.zcode/v2/config.json (providers are jq-merged by activation),
      # but AGENTS.md is only ever read, never rewritten by the app.
      (lib.mkIf (cfg.zcode.enable && cfg.globalInstructions != "") {
        ".zcode/AGENTS.md" = {
          text = cfg.globalInstructions;
          force = true;
        };
      })

      # === DeepSeek Harness (dsh): user-global instructions (~/.dsh/AGENTS.md) ===
      # dsh-agent-instructions treats ~/.dsh/AGENTS.md as the user-global
      # instruction file, layered above workspace AGENTS.md/CLAUDE.md
      # discovery. Only read by dsh, never rewritten.
      (lib.mkIf (cfg.dsh.enable && cfg.globalInstructions != "") {
        ".dsh/AGENTS.md" = {
          text = cfg.globalInstructions;
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
      # MiMoCode RE agent-specific MCP fragments (merged into the runtime overlay by mimo launchers)
      (lib.mkIf cfg.enable {
        "mimocode/android-re-mcp-servers.json" = {
          text = toJSON opencodeAndroidReMcpServers;
          force = true;
        };
      })
      (lib.mkIf cfg.enable {
        "mimocode/web-re-mcp-servers.json" = {
          text = toJSON opencodeWebReMcpServers;
          force = true;
        };
      })
      # omp RE agent-specific MCP fragments (merged into the runtime overlay by omp launchers)
      (lib.mkIf cfg.enable {
        ".omp/agent/android-re-mcp-servers.json" = {
          text = toJSON ompAndroidReMcpServers;
          force = true;
        };
      })
      # herdr integration for OpenCode: state plugin (auto-discovered from
      # plugins/), V1 TUI session plugin + tui.jsonc registration, and the V2
      # TUI plugin dir (herdr-opencode/tui.js, a shim re-exporting the V1
      # plugin). herdr requires all of them or `herdr integration status`
      # reports "needs repair" once cli.json exists; the cli.json plugins
      # entry itself is merged by activation (herdr-setup.nix).
      (lib.mkIf (cfg.herdr.enable && cfg.opencode.enable) {
        "opencode/plugins/herdr-agent-state.js" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/herdrdev/herdr/${herdrAssetRev}/src/integration/assets/opencode/herdr-agent-state.js";
            sha256 = "sha256-Gmrr9mMjJP7GPR3iJnN7n6azXz3bUc5odDnma2x8tHU=";
          };
          force = true;
        };
        "opencode/herdr-tui-session.js" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/herdrdev/herdr/${herdrAssetRev}/src/integration/assets/opencode/herdr-tui-session.js";
            sha256 = "sha256-+bXC2xabDww4p4vCyDQReGc7wNAOX3BXdlrqc93Ff5U=";
          };
          force = true;
        };
        "opencode/herdr-opencode/tui.js" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/herdrdev/herdr/${herdrAssetRev}/src/integration/assets/opencode/tui.js";
            sha256 = "sha256-lLjRB+GrW/+iMg47fxVNGEiiFniHhaKbhtc1urNa+eg=";
          };
          force = true;
        };
        "opencode/tui.jsonc" = {
          text = toJSON { plugin = [ "./herdr-tui-session.js" ]; };
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
