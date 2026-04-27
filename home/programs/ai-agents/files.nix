# Home file and XDG config file declarations for AI agents.

{
  config,
  constants,
  lib,
  ...
}:

let
  cfg = config.programs.aiAgents;

  inherit (builtins) toJSON;

  fileTemplates = import ./helpers/_file-templates.nix;
  geminiPolicies = import ./helpers/_gemini-policies.nix;
  impeccable = import ./helpers/_impeccable-commands.nix;
  models = import ./helpers/_models.nix;
  agentEnvContent = import ./helpers/_agent-env.nix { inherit constants; };
  settingsBuilders = import ./helpers/_settings-builders.nix { inherit cfg config lib; };
  inherit (settingsBuilders)
    geminiSettings
    opencodeSettingsByProfile
    forgeTomlByProfile
    forgeMcpJson
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

  forgeProfiles = import ./helpers/_forge-profiles.nix { inherit config; };
  forgeProfileConfigFiles =
    let
      agentConcepts = fileTemplates;
    in
    builtins.listToAttrs (
      lib.flatten (
        map (
          profile:
          let
            profileDir = ".${profile.name}";
          in
          [
            # MCP servers
            # Global instructions via AGENTS.md
          ]
          ++ (lib.optional (cfg.globalInstructions != "") {
            name = "${profileDir}/AGENTS.md";
            value = {
              text = cfg.globalInstructions;
              force = true;
            };
          })
          # Forge agent definitions (markdown with YAML frontmatter)
          ++ (lib.mapAttrsToList (name: text: {
            name = "${profileDir}/agents/${name}";
            value = {
              inherit text;
              force = true;
            };
          }) fileTemplates.forgeAgents)
        ) forgeProfiles.profiles
      )
    );

  # Pi profile config files: settings.json, models.json, auth.json per profile.
  piProfiles = import ./helpers/_pi-profiles.nix { inherit config; };
  piSettingsBuilders = import ./helpers/_pi-settings-builder.nix { inherit cfg config lib; };
  inherit (piSettingsBuilders) piSettingsByProfile piModelsByProfile piAuthByProfile;

  piProfileConfigFiles = builtins.listToAttrs (
    lib.flatten (
      map (
        profile:
        let
          profileDir = ".pi/profiles/${profile.name}";
        in
        [
          # settings.json — model, thinking, compaction, retry, resource paths
          {
            name = "${profileDir}/settings.json";
            value = {
              text = toJSON piSettingsByProfile.${profile.name};
              force = true;
            };
          }
          # models.json — custom providers (Z.AI, OpenRouter, etc.)
          {
            name = "${profileDir}/models.json";
            value = {
              text = toJSON piModelsByProfile.${profile.name};
              force = true;
            };
          }
          # auth.json — API key entries (shell command resolution for secrets)
          {
            name = "${profileDir}/auth.json";
            value = {
              text = toJSON piAuthByProfile.${profile.name};
              force = true;
            };
          }
        ]
        # AGENTS.md — global instructions
        ++ (lib.optional (cfg.globalInstructions != "") {
          name = "${profileDir}/AGENTS.md";
          value = {
            text = cfg.globalInstructions;
            force = true;
          };
        })
      ) piProfiles.profiles
    )
  );

  # Shared extensions installed to the default ~/.pi/agent/ directory.
  # These are available to all profiles since they share the same agent dir.
  piSharedExtensionFiles =
    let
      mcpManifest = import ./helpers/_mcp-transforms.nix { inherit cfg lib; };
    in
    builtins.listToAttrs (
      lib.optional cfg.pi.mcpBridge.enable {
        name = ".pi/agent/extensions/mcp-bridge.ts";
        value = {
          source = ./helpers/pi-extensions/mcp-bridge.ts;
          force = true;
        };
      }
      ++ lib.optional cfg.pi.subagent.enable {
        name = ".pi/agent/extensions/subagent.ts";
        value = {
          source = ./helpers/pi-extensions/subagent.ts;
          force = true;
        };
      }
      ++ lib.optional cfg.pi.gitCheckpoint.enable {
        name = ".pi/agent/extensions/git-checkpoint.ts";
        value = {
          source = ./helpers/pi-extensions/git-checkpoint.ts;
          force = true;
        };
      }
      # Agent switcher — /agent command for persona switching (implementation-engineer, static-recon, etc.)
      ++ [
        {
          name = ".pi/agent/extensions/agent-switcher.ts";
          value = {
            source = ./helpers/pi-extensions/agent-switcher.ts;
            force = true;
          };
        }
      ]
      # MCP manifest — JSON config listing all MCP servers for the bridge extension to spawn.
      ++ lib.optional cfg.pi.mcpBridge.enable {
        name = ".pi/agent/mcp-manifest.json";
        value = {
          text = toJSON { servers = mcpManifest.piMcpManifest; };
          force = true;
        };
      }
      # Agent definitions — same canonical concepts as Claude/Forge agents, in SKILL.md format.
      # These are loaded by the /agent extension command for persona switching.
      ++ (lib.mapAttrsToList (name: text: {
        name = ".pi/agent/agents/${name}";
        value = {
          inherit text;
          force = true;
        };
      }) fileTemplates.piAgents)
      # Custom pi skills (init, deep-init) — become /skill:init and /skill:deep-init commands.
      ++ [
        {
          name = ".pi/agent/skills/init/SKILL.md";
          value = {
            source = ./helpers/pi-skills/init/SKILL.md;
            force = true;
          };
        }
        {
          name = ".pi/agent/skills/deep-init/SKILL.md";
          value = {
            source = ./helpers/pi-skills/deep-init/SKILL.md;
            force = true;
          };
        }
      ]
    );
in
{
  config = lib.mkIf cfg.enable {
    home.file = lib.mkMerge [
      # === Claude Agent Definitions ===
      (lib.mkIf cfg.claude.enable (mkTextFiles ".claude/agents" fileTemplates.claudeAgents))

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

      # === Gemini Files (Settings, Commands, Skills) ===
      (lib.mkIf cfg.gemini.enable (
        {
          ".gemini/settings.json" = {
            text = toJSON geminiSettings;
            force = true;
          };
        }
        // (mkTextFiles ".gemini/commands" fileTemplates.geminiCommands)
        // (mkTextFiles ".gemini/skills" fileTemplates.geminiSkills)
        // (mkTextFiles ".gemini/policies" geminiPolicies)
      ))

      # === Forge Profile Configs (one directory per profile) ===
      (lib.mkIf cfg.forge.enable forgeProfileConfigFiles)

      # === Pi Profile Configs (settings, models, auth per profile) ===
      (lib.mkIf cfg.pi.enable piProfileConfigFiles)

      # === Pi Shared Extensions & MCP Manifest ===
      (lib.mkIf cfg.pi.enable piSharedExtensionFiles)
    ];

    xdg.configFile = lib.mkMerge [
      # Runtime model/service config for shell scripts (always available when agents enabled)
      (lib.mkIf cfg.enable {
        "ai-agents/models.sh" = {
          text = agentEnvContent;
          force = true;
        };
      })
      # OpenCode profile configs
      (lib.mkIf cfg.opencode.enable (opencodeConfigFiles // opencodeImpeccableCommandFiles))
    ];
  };
}
