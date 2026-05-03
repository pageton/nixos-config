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
  settingsBuilders = import ./helpers/_settings-builders.nix { inherit cfg config lib; };
  inherit (settingsBuilders)
    geminiSettings
    ompSettings
    opencodeSettingsByProfile
    omoOpencodeSettingsByProfile
    omoConfigsByProfile
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

  omoProfiles = import ./helpers/_omo-profiles.nix { inherit config; };
  omoConfigFiles = builtins.listToAttrs (
    lib.flatten (
      map (name: [
        {
          name = "${name}/opencode.json";
          value = {
            text = toJSON omoOpencodeSettingsByProfile.${name};
            force = true;
          };
        }
        {
          name = "${name}/oh-my-openagent.json";
          value = {
            text = toJSON omoConfigsByProfile.${name};
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
      ]) omoProfiles.names
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
              hash = "sha256-BrRDo7tDagCNIXtZfh7zMKo6b16pSdh7Bu/gixEjVaA=";
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
  piSettingsBuilders = import ./helpers/_pi-settings-builder.nix {
    inherit
      cfg
      config
      lib
      ;
  };
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
              hash = "sha256-BrRDo7tDagCNIXtZfh7zMKo6b16pSdh7Bu/gixEjVaA=";
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
      (lib.mkIf cfg.opencode.enable (
        opencodeConfigFiles // opencodeImpeccableCommandFiles // omoConfigFiles
      ))
    ];
  };
}
