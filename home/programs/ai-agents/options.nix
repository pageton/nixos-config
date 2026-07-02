# Option definitions for programs.aiAgents.

{
  config,
  constants,
  lib,
  ...
}:

let
  opt = import ../../../shared/option-helpers.nix { inherit lib; };
  inherit (opt)
    mkTypedOption
    mkStrOption
    mkBoolOption
    mkIntOption
    mkAttrsOption
    mkAttrsOfStrOption
    mkStrListOption
    mkLinesOption
    mkNullOrStrOption
    mkNullableOption
    ;

  # Shared Codex enum types — used by top-level, profiles, and customAgents options.
  codexPersonalityType = lib.types.enum [
    "none"
    "friendly"
    "pragmatic"
  ];
  codexReasoningEffortType = lib.types.enum [
    "none"
    "minimal"
    "low"
    "medium"
    "high"
    "xhigh"
  ];
  codexApprovalPolicyType = lib.types.enum [
    "untrusted"
    "on-failure"
    "on-request"
    "never"
  ];
  codexReasoningEffortNullable = lib.types.nullOr codexReasoningEffortType;
  codexApprovalPolicyNullable = lib.types.nullOr codexApprovalPolicyType;

  # Shared option set for Codex profiles and custom agents.
  mkCodexEntityOpts =
    extraOpts:
    lib.types.submodule {
      options = {
        model = mkNullOrStrOption null "Model override";
        reasoningEffort = lib.mkOption {
          type = codexReasoningEffortNullable;
          default = null;
          description = "Reasoning effort level";
        };
        approvalPolicy = lib.mkOption {
          type = codexApprovalPolicyNullable;
          default = null;
          description = "Command approval policy";
        };
        sandboxMode = mkNullOrStrOption null "Sandbox mode";
        enableSearch = mkBoolOption false "Enable native Codex web search";
        developerInstructions = mkLinesOption "" "Developer instructions";
        extraToml = mkLinesOption "" "Extra TOML content";
      }
      // extraOpts;
    };

  mcpServerType = lib.types.submodule {
    options = {
      enable = mkBoolOption true "Enable this MCP server";
      type = mkTypedOption (lib.types.enum [
        "local"
        "remote"
      ]) "local" "Server type (local stdio or remote HTTP)";
      command = mkStrOption "" "Command to run for local servers";
      args = mkStrListOption [ ] "Arguments for the command";
      url = mkNullOrStrOption null "URL for remote MCP servers";
      headers = mkNullableOption (lib.types.attrsOf lib.types.str) null "Headers for remote MCP servers";
      env = mkAttrsOfStrOption { } "Environment variables for the server";
    };
  };

  mkMcpServersOption = description: {
    type = lib.types.attrsOf mcpServerType;
    default = { };
    inherit description;
  };
in
{
  options.programs.aiAgents = {
    # === Core Options ===
    enable = lib.mkEnableOption "AI coding agents configuration";

    globalInstructions = mkLinesOption "" "Global instructions injected into all AI agents (Claude CLAUDE.md, OpenCode instructions, Codex developer_instructions, Antigravity systemInstruction)";

    secrets = {
      zaiApiKeyFile = mkNullOrStrOption "/run/secrets/zai_api_key" "Path to sops-decrypted Z.AI API key file";
      openrouterApiKeyFile = mkNullOrStrOption "/run/secrets/openrouter_api_key" "Path to sops-decrypted OpenRouter API key file";
      context7ApiKeyFile = mkNullOrStrOption "/run/secrets/context7-api-key" "Path to sops-decrypted Context7 API key file";
      minimaxApiKeyFile = mkNullOrStrOption "/run/secrets/minimax_api_key" "Path to sops-decrypted MiniMax API key file";
      deepseekApiKeyFile = mkNullOrStrOption "/run/secrets/deepseek_api_key" "Path to sops-decrypted DeepSeek API key file";
      mimoApiKeyFile = mkNullOrStrOption "/run/secrets/mimo_api_key" "Path to sops-decrypted Xiaomi MiMo API key file";
      openaiApiKeyFile = mkNullOrStrOption "/run/secrets/openai_api_key" "Path to sops-decrypted OpenAI API key file";
    };

    skills = lib.mkOption {
      type = lib.types.listOf (
        lib.types.either lib.types.str (
          lib.types.submodule {
            options = {
              repo = lib.mkOption {
                type = lib.types.str;
                description = "GitHub repository (e.g., 'vercel-labs/skills')";
              };
              skill = lib.mkOption {
                type = lib.types.str;
                description = "Individual skill name from the repository";
              };
            };
          }
        )
      );
      default = [ ];
      description = ''
        List of skills to install from skills.sh.
        Use a string for repo-level installs (e.g., "obra/superpowers").
        Use an attrset { repo, skill } for individual skills
        (e.g., { repo = "vercel-labs/skills"; skill = "find-skills"; }).
      '';
      example = [
        "obra/superpowers"
        {
          repo = "vercel-labs/skills";
          skill = "find-skills";
        }
      ];
    };

    agencyAgents = {
      enable = mkBoolOption false "Install msitarzewski/agency-agents for Claude and OpenCode";
    };

    impeccable = {
      enable = mkBoolOption false "Install pbakaus/impeccable skills for Claude and OpenCode";
    };

    agentmemory = {
      enable = mkBoolOption false "Enable shared persistent memory via agentmemory MCP";
      version = mkStrOption "0.9.16" "agentmemory npm package version for the service and MCP shim";
      url = mkStrOption "http://localhost:3111" "Base URL for the local agentmemory server";
      viewerUrl = mkStrOption "http://localhost:3113" "URL for the local agentmemory viewer";
    };

    herdr = {
      enable = mkBoolOption false "Install herdr agent multiplexer";
    };

    codegraph = {
      enable = mkBoolOption false "Enable CodeGraph pre-indexed code knowledge graph MCP server";
      npmPackage = mkStrOption "@colbymchenry/codegraph" "CodeGraph npm package name";
    };

    serena = {
      enable = mkBoolOption false "Enable Serena MCP coding toolkit (semantic retrieval, editing, refactoring)";
      package = mkStrOption "serena-agent" "Serena Python package name (installed via uv)";
    };

    everythingClaudeCode = {
      enable = mkBoolOption false "Install a curated Everything Claude Code subset for Claude, Codex, and OpenCode";

      claude = {
        enable = mkBoolOption true "Install curated Everything Claude Code assets for Claude Code";
        commands = mkStrListOption [
          "add-language-rules"
          "database-migration"
          "feature-development"
        ] "Claude command files to install from Everything Claude Code";
        installSkillPack = mkBoolOption true "Install the upstream Everything Claude Code Claude skill pack";
      };

      codex = {
        enable = mkBoolOption true "Install curated Everything Claude Code assets for Codex";
        agents = mkStrListOption [
          "docs-researcher"
          "explorer"
          "reviewer"
        ] "Codex agent files to install from Everything Claude Code";
      };

      opencode = {
        enable = mkBoolOption true "Install curated Everything Claude Code assets for OpenCode";
        commands = mkStrListOption [
          "plan"
          "code-review"
          "verify"
          "tdd"
        ] "OpenCode command files to install from Everything Claude Code";
        installInstructions = mkBoolOption true "Install the upstream OpenCode instruction bundle from Everything Claude Code";
      };

    };

    speckit = {
      enable = mkBoolOption false "Install github/spec-kit spec-driven-development slash commands";

      claude = {
        enable = mkBoolOption true "Install spec-kit commands into Claude Code";
        commands = mkStrListOption [
          "specify"
          "plan"
          "tasks"
          "analyze"
          "checklist"
          "clarify"
          "constitution"
          "implement"
          "taskstoissues"
        ] "Spec-kit command templates to install for Claude Code (stems under templates/commands/*.md)";
      };

      codex = {
        enable = mkBoolOption true "Install spec-kit commands into Codex";
        commands = mkStrListOption [
          "specify"
          "plan"
          "tasks"
          "analyze"
          "checklist"
          "clarify"
          "constitution"
          "implement"
          "taskstoissues"
        ] "Spec-kit command templates to install for Codex (stems under templates/commands/*.md)";
      };

      opencode = {
        enable = mkBoolOption true "Install spec-kit commands into OpenCode command dirs";
        commands = mkStrListOption [
          "specify"
          "plan"
          "tasks"
          "analyze"
          "checklist"
          "clarify"
          "constitution"
          "implement"
          "taskstoissues"
        ] "Spec-kit command templates to install for OpenCode (stems under templates/commands/*.md)";
      };
    };

    mcpServers = lib.mkOption (mkMcpServersOption "Shared MCP server definitions used by all agents");

    androidReMcpServers = lib.mkOption (
      mkMcpServersOption "MCP servers only loaded for the android-re agent (not shared globally)"
    );

    webReMcpServers = lib.mkOption (mkMcpServersOption "MCP servers only loaded for the web-re agent.");

    logging = {
      enable = lib.mkEnableOption "centralized logging for AI agents";

      directory = mkStrOption "${config.xdg.dataHome}/ai-agents/logs" "Directory for AI agent logs";
      notifyOnError = mkBoolOption true "Send desktop notification on agent errors";
      enableOtel = mkBoolOption false "Enable OpenTelemetry for supported agents";
      otelEndpoint = mkStrOption "http://localhost:${toString constants.ports.otel}" "OpenTelemetry collector endpoint";
      otelExporter = mkStrOption "otlp" "OpenTelemetry exporter type";
      retentionDays = mkIntOption 30 "Days to retain log files";
    };

    # === Claude Options ===
    claude = {
      enable = lib.mkEnableOption "Claude Code configuration";

      model = mkStrOption "opus" "Default model for Claude Code";
      env = mkAttrsOfStrOption { } "Environment variables for Claude Code";
      permissions = mkAttrsOption {
        allow = [ ];
        deny = [ ];
      } "Permission rules for Claude Code";
      hooks = mkAttrsOption { } "Lifecycle hooks for Claude Code";
      extraSettings = mkAttrsOption { } "Additional Claude Code settings";
    };

    # === OpenCode Options ===
    opencode = {
      enable = lib.mkEnableOption "OpenCode configuration";

      model = mkStrOption "opencode/claude-opus-4-7" "Default model for OpenCode";
      plugins = mkStrListOption [ ] "OpenCode plugins to enable";
      providers = mkAttrsOption { } "Provider configurations for OpenCode";
      permission =
        mkTypedOption (lib.types.either lib.types.str lib.types.attrs) { }
          "OpenCode permission policy";
      agent = mkAttrsOption { } "OpenCode agent definitions";
      command = mkAttrsOption { } "OpenCode slash command definitions";
      lsp =
        mkTypedOption (lib.types.either lib.types.bool lib.types.attrs) { }
          "OpenCode LSP server configuration";
      formatter =
        mkTypedOption (lib.types.either lib.types.bool lib.types.attrs) { }
          "OpenCode formatter configuration";
      experimental = mkAttrsOption { } "OpenCode experimental feature flags";
      defaultAgent = mkNullOrStrOption null "Default primary agent for OpenCode";
      enabledProviders = mkStrListOption [ ] "Only enable these OpenCode providers";
      disabledProviders = mkStrListOption [ ] "Disable these auto-loaded OpenCode providers";
      extraSettings = mkAttrsOption { } "Additional OpenCode settings";
    };

    # === Codex Options ===
    codex = {
      enable = lib.mkEnableOption "Codex CLI configuration";

      model = mkStrOption "openai/gpt-5.5" "Default model for Codex";
      sandboxMode = mkStrOption "workspace-write" "Default sandbox mode for Codex";
      # Active only at top-level codex settings.
      enableSearch = mkBoolOption false "Enable native Codex web search by default";

      personality = lib.mkOption {
        type = codexPersonalityType;
        default = "pragmatic";
        description = "Model personality";
      };

      reasoningEffort = lib.mkOption {
        type = codexReasoningEffortType;
        default = "medium";
        description = "Reasoning effort level";
      };

      approvalPolicy = lib.mkOption {
        type = codexApprovalPolicyType;
        default = "on-request";
        description = "Command approval policy";
      };

      trustedProjects = mkStrListOption [ ] "Paths to projects with trust_level = trusted";

      features = mkTypedOption (lib.types.attrsOf lib.types.bool) { } "Feature flags for Codex";

      profiles = mkTypedOption (lib.types.attrsOf (mkCodexEntityOpts {
        personality = lib.mkOption {
          type = lib.types.nullOr codexPersonalityType;
          default = null;
          description = "Profile-specific personality override";
        };
      })) { } "Named Codex config profiles";

      customAgents = mkTypedOption (lib.types.attrsOf (mkCodexEntityOpts {
        description = mkStrOption "" "Human-facing description for when to use this custom Codex agent";
      })) { } "Custom Codex agents written to ~/.codex/agents/*.toml";

      extraToml = mkLinesOption "" "Extra TOML lines appended to config.toml";
    };

    # === Antigravity Options ===
    antigravity = {
      enable = lib.mkEnableOption "Antigravity CLI (agy) configuration";

      theme = mkStrOption "Default" "Theme for Antigravity CLI";
      sandboxMode = mkStrOption "cautious" "Sandbox mode (none, cautious, strict)";
      extraSettings = mkAttrsOption { } "Additional Antigravity CLI settings";
    };

    # === Oh My Pi (omp) Options ===
    omp = {
      enable = lib.mkEnableOption "Oh My Pi (omp) coding agent configuration";
    };

  };
}
