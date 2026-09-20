# AI Agents Infrastructure

High-density orchestration for Claude Code, OpenCode, Codex CLI, Antigravity, MiMoCode, Oh My Pi (omp), and DeepSeek Harness (dsh). This module manages dynamic provider switching, shared MCP servers, skill mirroring, and secure secret injection.

---

## OVERVIEW

This module centralizes AI agent behavior across multiple CLI tools. It implements a layered configuration system that translates high-level Nix options into tool-specific JSON/TOML formats, enriched with lifecycle hooks and shared MCP capabilities.

---

## ARCHITECTURE

The system follows a strict unidirectional flow:

1. **Options** (`options.nix`): Defines the `programs.aiAgents.*` namespace.
2. **Config Hub** (`config/`): Domain-specific values for models, prompts, and permissions.
3. **Helpers** (`helpers/`): Shared logic imported by config, activation, and files modules.
4. **File Generation** (`files.nix`): Declares configuration files in XDG paths.
5. **Activation Logic** (`activation/`): Handles late-stage secret injection, config setup, best-effort skill management, and state caching.
6. **Services** (`services.nix`): Packages, zsh aliases, and systemd user services/timers.
7. **Log Analyzer** (`log-analyzer.nix`): AI agent log analysis and dashboard.

### Oh My ClaudeCode (OMC)

OMC is a Claude Code marketplace plugin that provides multi-agent orchestration. Its installation is managed by Claude Code's plugin system. This Nix module manages OMC's **runtime configuration** (`~/.config/claude-omc/config.jsonc`) and **environment variables** for model routing, features, permissions, and team settings. Plugin installation/removal stays with Claude Code's marketplace.

### Oh My Pi (omp)

omp (fork of pi-mono) is a coding agent with subagents, LSP/DAP, and hindsight memory. The Nix module manages its **MCP config** (`~/.omp/agent/mcp.json`, derived from the shared `programs.aiAgents.mcpServers` via the `ompMcpServers` transform), **global instructions** (`~/.omp/agent/AGENTS.md` from `cfg.globalInstructions` — omp's native user context file, highest discovery priority), **skills** (mirrored into `~/.omp/agent/skills` by the activation skill-sync), **herdr agent state extension** (`~/.omp/agent/extensions/herdr-omp-agent-state.ts`, fetched from herdr assets at the flake input's locked rev), and the **`omp` zsh alias + autoupdate**. MCP secrets are patched into `mcp.json` at activation alongside the other agents. Model/provider selection stays with omp's interactive `~/.omp/agent/` config. omp owns `~/.omp/agent/config.yml` (YAML, sparse writes): the `setupOmpConfig` activation step yq-merges managed keys (currently `mcp.enableProjectConfig: false`, which blocks project-level MCP sources) while preserving app/user settings.

### Antigravity CLI (agy)

agy owns its config and uses the Antigravity-native layout, not the legacy Gemini CLI layout: settings live in `~/.gemini/antigravity-cli/settings.json` (sparse persistence), MCP servers in `~/.gemini/config/mcp_config.json` (remote transports require `serverUrl`, not `url`/`httpUrl`), global skills in `~/.gemini/antigravity-cli/skills/`, and global context in `~/.gemini/GEMINI.md`. The `setupAntigravityConfig` activation step jq-merges managed settings and MCP servers into the app-owned files (managed keys win, app keys survive) and removes a legacy `~/.gemini/settings.json` when it still carries the Home-Manager signature. Global skills are flat markdown files with `name`/`description` frontmatter (see `_file-templates.nix` `antigravitySkills`); activation mirrors Claude skills into the same directory. Terminal sandboxing (`enableTerminalSandbox`) stays off because nsjail is not installed.

### ZCode

ZCode (Z.AI desktop app) owns its config: `~/.zcode/v2/config.json` (providers/models) and `~/.zcode/v2/setting.json` (settings) are rewritten by the running app, so managed keys are injected by the `setupZcodeConfig` activation step as idempotent jq merges (never `home.file` declarations). Providers come from the `programs.aiAgents.zcode.providers` option (defaults in `helpers/_zcode-providers.nix`): entries are matched by baseURL substring so UI-created provider UUIDs are reused, not duplicated; models are deep-merged (array-safe recursive merge — jq `*` errors on differing-length arrays) so UI-added models survive unless `mergeModels = false`. Settings come from `programs.aiAgents.zcode.extraSettings` (defaults in `config/models/zcode.nix`): deep-merged with managed keys winning, volatile UI state (recentProjects, window size, device pairing, locale) stays app-owned. The registry covers three providers: OpenCode Zen (kind `openai-compatible` — Zen free models only answer on `chat/completions`), OpenRouter (kind `anthropic`, free-tier models), and DeepSeek (kind `anthropic`, api.deepseek.com/anthropic). API keys come from sops via the per-provider `secret` (a `programs.aiAgents.secrets` option name) or explicit `keyFile`, with a fallback to keys already stored by the app. User-global instructions land in `~/.zcode/AGENTS.md` (ZCode reads it but never rewrites it, so a `home.file` declaration is safe). Restart ZCode after activation; the app holds providers in memory.

### Profile-Driven Polymorphism

OpenCode profiles switch the primary model across all OpenCode config directories. Each profile re-maps the model field via `helpers/_settings-builders.nix`, allowing instant provider migration with zero configuration redundancy.

Seven OpenCode profiles are defined in `helpers/_opencode-profiles.nix`:

| Profile Directory     | Provider/Model                                    |
| --------------------- | ------------------------------------------------- |
| `opencode`            | Default (from `programs.aiAgents.opencode.model`) |
| `opencode-glm`        | Z.AI GLM-5.3                                      |
| `opencode-gemini`     | Google Gemini 3 Pro Preview                       |
| `opencode-gpt`        | OpenAI GPT-5.4                                    |
| `opencode-openrouter` | OpenRouter Hunter Alpha                           |
| `opencode-sonnet`     | Anthropic Claude Sonnet 4.6                       |
| `opencode-zen`        | MiniMax M2.5 Free                                 |

---

## DIRECTORY STRUCTURE

```
ai-agents/
├── default.nix              # Import hub (options, activation, files, services, log-analyzer, config)
├── options.nix              # All programs.aiAgents option definitions
├── files.nix                # home.file + xdg.configFile declarations
├── services.nix             # Packages, zsh aliases, systemd user services/timers
├── log-analyzer.nix         # AI agent log analysis and dashboard
├── zcode-package.nix        # ZCode Desktop App package
├── helpers/                 # Shared logic (not modules, imported by others)
│   ├── _settings-builders.nix   # Per-agent settings + profile variant overrides
│   ├── _mcp-transforms.nix      # Unified MCP abstraction (shared → agent-specific schemas)
│   ├── _opencode-profiles.nix   # OpenCode profile names and config paths
│   ├── _aliases.nix             # Zsh alias generation for agent launchers/workflows
│   ├── _destructive-rules.nix   # Destructive action allow/deny rules per agent
│   ├── _file-templates.nix      # Config file templates
│   ├── _workflow-prompts.nix    # Workflow prompt definitions
│   ├── _zai-services.nix        # Z.AI MCP service registry
│   ├── _zai-filters.nix         # Z.AI MCP jq filter generation
│   ├── _mk-cli-autoupdate-script.nix     # CLI autoupdate script builder
│   ├── _services-shell-aliases.nix       # Shell alias definitions for agent services
│   ├── _services-systemd.nix             # Systemd user service/timer definitions
│   ├── _formatters.nix                   # Formatter registry (shared by claude hooks + gemini config)
│   ├── _impeccable-commands.nix          # Impeccable skill command definitions and text renderer
│   ├── _models.nix                       # Shared model/provider constants (names, aliases)
│   ├── _agent-env.nix                    # Runtime model/service env vars for shell scripts
│   ├── _agentmemory-runtime.nix          # agentmemory npm service + MCP shim packaging
│   ├── _herdr-mimo-plugin.nix            # Vendored herdr plugin for MiMoCode (herdr has no mimo target)
│   ├── _zai-env.nix                      # Z.AI service env var generation
│   └── _git-clone-update.nix             # Git clone/update helper for plugin repos
├── activation/              # Home Manager activation scripts
│   ├── default.nix          # Aggregation: wires all activation steps
│   ├── secrets.nix          # Secret patching (placeholder → real key injection)
│   ├── claude-setup.nix     # Claude Code config file writes
│   ├── codex-setup.nix      # Codex CLI config.toml + profile files + custom agents
│   ├── antigravity-setup.nix # agy settings + mcp_config.json jq merge
│   ├── omp-setup.nix        # omp config.yml yq merge
│   ├── plugins.nix          # Plugin aggregation (impeccable, agency-agents, ECC)
│   ├── _plugin-impeccable.nix # Impeccable skill install
│   ├── _plugin-agency-agents.nix # Agency agents install
│   ├── _plugin-everything-claude-code.nix # ECC skill install
│   ├── _plugin-oh-my-claudecode.nix # OMC config generation (jq merge)
│   ├── _cleanup-agency-agents.nix # Agency agents cleanup on disable
│   ├── zcode-setup.nix    # ZCode provider/model merge (cfg.zcode.providers) + setting.json merge (cfg.zcode.extraSettings)
│   ├── herdr-setup.nix    # herdr OpenCode V2 plugin registration (jq merge into app-owned cli.json)
│   ├── _cleanup-everything-claude-code.nix # ECC cleanup on disable
│   └── skills.nix           # Skill installations and omissions
├── android-re/              # Android RE workflow prompts and config
│   ├── _prompt.nix          # Prompt templates (not a module, imported by services)
│   └── prompts/             # RE session prompts and operator guides
│       ├── AGENTS.md        # Quick rules for RE sessions
│       ├── README.md        # Operator guide and workflow map
│       ├── WORKFLOW.md      # End-to-end RE workflow
│       ├── TOOLS.md         # Installed tools and recommendations
│       └── TROUBLESHOOTING.md # Known issues and recovery
└── config/                  # Split configuration values
    ├── default.nix          # Import hub
    ├── defaults.nix         # Default values for agent options
    ├── global-instructions.md # Global instructions text (not a module)
    ├── _skills.nix          # Skill installations and omissions
    ├── mcp-servers.nix      # MCP server definitions + logging
    ├── claude/              # Claude Code configuration
    │   ├── default.nix      # Import hub (permissions, hooks, settings)
    │   ├── _hooks.nix       # Lifecycle hooks aggregation (imports helpers + per-stage modules)
    │   ├── _hooks-helpers.nix # Shared hook constructors (mkFormatterHook, mkBashHook, etc.)
    │   ├── _hooks-pre-tool-use.nix  # Pre-tool-use safety hooks
    │   ├── _hooks-post-tool-use.nix # Post-tool-use auto-format hooks
    │   ├── _hooks-session.nix      # Session lifecycle hooks
    │   └── _permission-rules.nix # Claude allow/deny rules
    └── models/              # Model/provider registries
        ├── default.nix      # Import hub + shared toggles (agencyAgents, impeccable)
        ├── antigravity.nix  # Antigravity CLI (agy) native settings + permissions
        ├── codex.nix        # Codex CLI configuration (profiles, custom agents, features)
        ├── opencode.nix     # OpenCode configuration (agents, LSP, providers)
        ├── zcode.nix        # ZCode managed settings (extraSettings defaults)
        └── _opencode-lsp.nix # OpenCode LSP tool configuration
```

---

## SECRETS

Secure secret injection is handled during the Home Manager activation phase to prevent sensitive keys from entering the Nix store.

1. **Placeholders**: Config files are written with unique placeholders (e.g., `__GITHUB_TOKEN_PLACEHOLDER__`, `__OPENROUTER_API_KEY_PLACEHOLDER__`).
2. **DAG Patching**: The `patchAiAgentSecrets` script runs as a DAG entry after `writeBoundary`.
3. **Injection**: It uses `jq` with walk filters for JSON files, reading keys directly from `/run/secrets/` or `gh` CLI and overwriting the placeholders in-place.

---

## CONVENTIONS

### Unified MCP Abstraction

Never define MCP servers per-agent. Define them once in `programs.aiAgents.mcpServers`. The `helpers/_mcp-transforms.nix` logic automatically generates the correct transport configuration for every supported agent.

### Helper File Rules

All `helpers/_*.nix` files are plain Nix expressions (not modules). They are imported with `import ../helpers/<name>.nix { ... }` by the modules that need them. They are never listed in import hubs.

### Activation File Rules

The `activation/` directory is a submodule with its own `default.nix`. Individual files (`secrets.nix`, `claude-setup.nix`, `codex-setup.nix`, `plugins.nix`, `skills.nix`) are helpers imported by `activation/default.nix` — not listed in the top-level `ai-agents/default.nix` import hub.

### Complexity Hotspots (WARNING)

This module contains significant **embedded Bash logic** that bypasses standard Nix abstraction for performance and compatibility:

- **`config/claude/_hooks.nix`**: Heavy use of `jq` and `grep` within Claude Code lifecycle hooks for auto-formatting and destructive command detection.
- **`activation/default.nix`**: Complex sequential skill installation/removal logic with state-caching to prevent redundant network calls; skill sync failures are logged as warnings so Home Manager activation can continue. Also handles mirroring Claude skills into `~/.codex/skills` and disabling the shared `~/.agents/skills` tree to prevent OpenCode duplicate-skill spam.

### Validation Pipeline

```bash
just modules   # Validate import tree
just lint      # Run statix/deadnix
just format    # nixfmt-tree
just check     # Full flake evaluation
just home      # Apply configuration
```
