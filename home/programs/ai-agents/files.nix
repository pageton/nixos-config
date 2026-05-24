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

  inherit (builtins) toJSON;

  fileTemplates = import ./helpers/_file-templates.nix;
  geminiPolicies = import ./helpers/_gemini-policies.nix;
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
    geminiSettings
    ompSettings
    opencodeSettingsByProfile
    opencodeAndroidReMcpServers
    opencodeWebReMcpServers
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

  # Oh My Pi (omp) profile config files: config.yml, models.yml per profile.
  ompProfiles = import ./helpers/_omp-profiles.nix { inherit config; };
  ompSettingsBuilders = import ./helpers/_omp-settings-builder.nix {
    inherit
      cfg
      config
      lib
      pkgs
      ;
  };
  inherit (ompSettingsBuilders) ompConfigsByProfile ompModelsByProfile;

  ompProfileConfigFiles = builtins.listToAttrs (
    lib.flatten (
      map (
        profile:
        let
          profileDir = ".omp/profiles/${profile.name}";
        in
        [
          {
            name = "${profileDir}/config.yml";
            value = {
              text = ompConfigsByProfile.${profile.name};
              force = true;
            };
          }
        ]
        ++ (lib.optional (ompModelsByProfile.${profile.name} != "") {
          name = "${profileDir}/models.yml";
          value = {
            text = ompModelsByProfile.${profile.name};
            force = true;
          };
        })
        ++ (lib.optional (cfg.globalInstructions != "") {
          name = "${profileDir}/AGENTS.md";
          value = {
            text = cfg.globalInstructions;
            force = true;
          };
        })
      ) ompProfiles.profiles
    )
  );

  # Skills deployed to ~/.omp/agent/skills/.
  ompSharedSkillFiles = builtins.listToAttrs (
    (map (name: {
      name = ".omp/agent/skills/${name}/SKILL.md";
      value = {
        source = ./helpers/pi-skills/${name}/SKILL.md;
        force = true;
      };
    }) (builtins.attrNames (builtins.readDir ./helpers/pi-skills)))
    ++ (
      let
        githubSkillRepos = [
          {
            owner = "samber";
            repo = "cc-skills-golang";
            rev = "main";
          }
        ];
        mkGithubSkills =
          {
            owner,
            repo,
            rev,
          }:
          let
            src = pkgs.fetchFromGitHub {
              inherit owner repo rev;
              hash = "sha256-nd0T2duTdX2CUfmqD5OiHgl7SNqjR6k5+0TvE6eig5A=";
            };
            entries = builtins.readDir src;
          in
          map
            (name: {
              name = ".omp/agent/skills/${name}/SKILL.md";
              value = {
                source = "${src}/${name}/SKILL.md";
                force = true;
              };
            })
            (
              builtins.filter (
                name: entries.${name} == "directory" && builtins.pathExists "${src}/${name}/SKILL.md"
              ) (builtins.attrNames entries)
            );
      in
      builtins.concatLists (map mkGithubSkills githubSkillRepos)
    )
  );

  # Pi (badlogic/pi-mono) profile config files: config.yml, models.yml per profile.
  piProfiles = import ./helpers/_pi-profiles.nix { inherit config; };
  piSettingsBuilders = import ./helpers/_pi-settings-builder.nix { inherit cfg config lib; };
  inherit (piSettingsBuilders) piConfigsByProfile piModelsByProfile;

  piProfileConfigFiles = builtins.listToAttrs (
    lib.flatten (
      map (
        profile:
        let
          profileDir = ".pi/profiles/${profile.name}";
        in
        [
          {
            name = "${profileDir}/config.yml";
            value = {
              text = piConfigsByProfile.${profile.name};
              force = true;
            };
          }
        ]
        ++ (lib.optional (piModelsByProfile.${profile.name} != "") {
          name = "${profileDir}/models.yml";
          value = {
            text = piModelsByProfile.${profile.name};
            force = true;
          };
        })
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

  # Skills deployed to ~/.pi/agent/skills/.
  piSharedSkillFiles = builtins.listToAttrs (
    (map (name: {
      name = ".pi/agent/skills/${name}/SKILL.md";
      value = {
        source = ./helpers/pi-skills/${name}/SKILL.md;
        force = true;
      };
    }) (builtins.attrNames (builtins.readDir ./helpers/pi-skills)))
    ++ (
      let
        githubSkillRepos = [
          {
            owner = "samber";
            repo = "cc-skills-golang";
            rev = "main";
          }
        ];
        mkGithubSkills =
          {
            owner,
            repo,
            rev,
          }:
          let
            src = pkgs.fetchFromGitHub {
              inherit owner repo rev;
              hash = "sha256-nd0T2duTdX2CUfmqD5OiHgl7SNqjR6k5+0TvE6eig5A=";
            };
            entries = builtins.readDir src;
          in
          map
            (name: {
              name = ".pi/agent/skills/${name}/SKILL.md";
              value = {
                source = "${src}/${name}/SKILL.md";
                force = true;
              };
            })
            (
              builtins.filter (
                name: entries.${name} == "directory" && builtins.pathExists "${src}/${name}/SKILL.md"
              ) (builtins.attrNames entries)
            );
      in
      builtins.concatLists (map mkGithubSkills githubSkillRepos)
    )
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
        ".pi/agent/extensions/herdr-agent-state.ts" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/ogulcancelik/herdr/v${cfg.herdr.version}/src/integration/assets/pi/herdr-agent-state.ts";
            sha256 = "sha256-cI++/hXltICQIUB04UuUfj4wvzTazShjLRLbPzjCOQ8=";
          };
          force = true;
        };
        ".claude/hooks/herdr-agent-state.sh" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/ogulcancelik/herdr/v${cfg.herdr.version}/src/integration/assets/claude/herdr-agent-state.sh";
            sha256 = "sha256-WejXy9UV7ZeoCa96C5cOGII9kYk1utUPRQDfguQUtrM=";
          };
          executable = true;
          force = true;
        };
        ".codex/herdr-agent-state.sh" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/ogulcancelik/herdr/v${cfg.herdr.version}/src/integration/assets/codex/herdr-agent-state.sh";
            sha256 = "sha256-5Xb1nbzIwr3T8srGBeJ7n8mH66ff8GvFURmFJQDdHeg=";
          };
          executable = true;
          force = true;
        };
        ".codex/hooks.json" = {
          text = toJSON {
            hooks = {
              SessionStart = [ { command = "~/.codex/herdr-agent-state.sh idle"; } ];
              UserPromptSubmit = [ { command = "~/.codex/herdr-agent-state.sh working"; } ];
              PreToolUse = [ { command = "~/.codex/herdr-agent-state.sh working"; } ];
              Stop = [ { command = "~/.codex/herdr-agent-state.sh idle"; } ];
            };
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

      # === Droid (Factory AI) Settings ===
      (lib.mkIf cfg.droid.enable {
        ".factory/settings.json" = {
          text = toJSON {
            customModels = [
              {
                displayName = "GLM-5.1 [Z.AI] - Anthropic";
                model = "glm-5.1";
                baseUrl = "https://api.z.ai/api/anthropic";
                apiKey = "__DROID_ZAI_API_KEY_PLACEHOLDER__";
                provider = "anthropic";
                maxOutputTokens = 131072;
              }
              {
                displayName = "GLM-5 Turbo [Z.AI] - Anthropic";
                model = "glm-5-turbo";
                baseUrl = "https://api.z.ai/api/anthropic";
                apiKey = "__DROID_ZAI_API_KEY_PLACEHOLDER__";
                provider = "anthropic";
                maxOutputTokens = 131072;
              }
              {
                displayName = "DeepSeek V4 Pro - Anthropic";
                model = "deepseek-v4-pro";
                baseUrl = "https://api.deepseek.com/anthropic";
                apiKey = "__DROID_DEEPSEEK_API_KEY_PLACEHOLDER__";
                provider = "anthropic";
                maxOutputTokens = 131072;
              }
              {
                displayName = "DeepSeek V4 Flash - Anthropic";
                model = "deepseek-v4-flash";
                baseUrl = "https://api.deepseek.com/anthropic";
                apiKey = "__DROID_DEEPSEEK_API_KEY_PLACEHOLDER__";
                provider = "anthropic";
                maxOutputTokens = 131072;
              }
            ];
          };
          force = true;
        };
      })

      # === Gemini Files (Settings, Commands, Policies) ===
      (lib.mkIf cfg.gemini.enable (
        {
          ".gemini/settings.json" = {
            text = toJSON geminiSettings;
            force = true;
          };
        }
        // (mkTextFiles ".gemini/commands" fileTemplates.geminiCommands)
        // (mkTextFiles ".gemini/policies" geminiPolicies)
      ))

      # === Forge Profile Configs (one directory per profile) ===
      (lib.mkIf cfg.forge.enable forgeProfileConfigFiles)

      # === Oh My Pi (omp) Profile Configs & Skills ===
      (lib.mkIf cfg.omp.enable (
        ompProfileConfigFiles
        // ompSharedSkillFiles
        // {
          ".omp/agent/mcp.json" = {
            text = toJSON ompSettings;
            force = true;
          };
        }
      ))

      # === Pi (badlogic/pi-mono) Profile Configs & Skills ===
      (lib.mkIf cfg.pi.enable (piProfileConfigFiles // piSharedSkillFiles))
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
      # herdr agent state plugin for OpenCode (auto-discovered from plugins/ dir)
      (lib.mkIf (cfg.herdr.enable && cfg.opencode.enable) {
        "opencode/plugins/herdr-agent-state.js" = {
          source = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/ogulcancelik/herdr/v${cfg.herdr.version}/src/integration/assets/opencode/herdr-agent-state.js";
            sha256 = "sha256-t3LNyyhbRnU7yUBA/hPlLW9IUPhJU5neQcud0IZQFqQ=";
          };
          force = true;
        };
      })
    ];
  };
}
