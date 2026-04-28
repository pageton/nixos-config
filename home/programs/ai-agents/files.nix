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

  # Oh My Pi (omp) profile config files: config.yml, models.yml per profile.
  # Auth is managed via agent.db (SQLite) — no auth.json needed.
  piProfiles = import ./helpers/_pi-profiles.nix { inherit config; };
  piSettingsBuilders = import ./helpers/_pi-settings-builder.nix { inherit cfg config lib pkgs; };
  inherit (piSettingsBuilders) piConfigsByProfile piModelsByProfile;

  piProfileConfigFiles = builtins.listToAttrs (
    lib.flatten (
      map (
        profile:
        let
          profileDir = ".omp/profiles/${profile.name}";
        in
        [
          # config.yml — model, thinking, compaction, retry, resource paths
          {
            name = "${profileDir}/config.yml";
            value = {
              text = piConfigsByProfile.${profile.name};
              force = true;
            };
          }
        ]
        # models.yml — custom providers (OpenRouter, etc.) — only if non-empty
        ++ (lib.optional (piModelsByProfile.${profile.name} != "") {
          name = "${profileDir}/models.yml";
          value = {
            text = piModelsByProfile.${profile.name};
            force = true;
          };
        })
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

  # Shared extension and resource files installed to ~/.omp/agent/.
  # Available to all profiles since they share the same agent dir.
  #
  # OMP natively supports MCP (via mcp.json), agent switching (via /agents),
  # and subagents (via Task tool). Only custom extensions are deployed here.
  piSharedExtensionFiles =
    let
      mcpTransforms = import ./helpers/_mcp-transforms.nix { inherit cfg lib; };
    in
    builtins.listToAttrs (
      # Git checkpoint — custom extension (not built into OMP).
      lib.optional cfg.pi.gitCheckpoint.enable {
        name = ".omp/agent/extensions/git-checkpoint.ts";
        value = {
          source = ./helpers/pi-extensions/git-checkpoint.ts;
          force = true;
        };
      }
      # Native MCP config — OMP discovers ~/.omp/agent/mcp.json automatically.
      ++ lib.optional (builtins.length (builtins.attrValues mcpTransforms.sharedMcpServers) > 0) {
        name = ".omp/agent/mcp.json";
        value = {
          text = toJSON { mcpServers = mcpTransforms.ompMcpServers; };
          force = true;
        };
      }
      # Agent definitions — OMP discovers ~/.omp/agent/agents/*/SKILL.md natively.
      ++ (lib.mapAttrsToList (name: text: {
        name = ".omp/agent/agents/${name}";
        value = {
          inherit text;
          force = true;
        };
      }) fileTemplates.piAgents)
      # Custom omp skills — auto-discovered from helpers/pi-skills/ directory.
      # Each subdirectory becomes ~/.omp/agent/skills/<name>/SKILL.md.
      ++ (map (name: {
        name = ".omp/agent/skills/${name}/SKILL.md";
        value = {
          source = ./helpers/pi-skills/${name}/SKILL.md;
          force = true;
        };
      }) (builtins.attrNames (builtins.readDir ./helpers/pi-skills)))
      # GitHub-sourced skills — fetched at build time from upstream repos.
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
                hash = "sha256-IHHPdoPH44sHDfV7c7RVr+S/CpayTk4j/3QHEIiab0k=";
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
