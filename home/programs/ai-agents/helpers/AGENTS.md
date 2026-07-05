# AI Agents — Helpers

Shared pure-Nix expression library imported by config, activation, and files modules. Plain functions returning attrsets — NOT Home Manager modules.

Parent: `home/programs/ai-agents/AGENTS.md`

---

## Files

### Model & Provider Layer

| File                   | Purpose                                                                            |
| ---------------------- | ---------------------------------------------------------------------------------- |
| `_models.nix`          | Single source of truth for model identifiers (claude-opus, gpt-default, glm, etc.) |
| `_agent-env.nix`       | Shell-sourceable config bridging `_models.nix` + `constants.nix` to runtime scripts (`scripts/ai/_agent-registry.sh`) |
| `_zai-services.nix`    | Z.AI MCP service registry: service names, MCP keys, base URL                       |
| `_zai-env.nix`         | Shared Z.AI provider env vars (used by claude_glm + android-re launchers)          |
| `_zai-filters.nix`     | Agent-specific jq filters for Z.AI MCP secret injection                            |

### Configuration Builders

| File                         | Purpose                                                                   |
| ---------------------------- | ------------------------------------------------------------------------- |
| `_settings-builders.nix`     | Per-agent settings builders; imports `_mcp-transforms`, `_formatters`, `_models` |
| `_mcp-transforms.nix`        | Unified MCP abstraction mapped to agent-specific schemas                  |
| `_formatters.nix`            | Formatter registry (biome, rustfmt, nixfmt, prettier, etc.)               |
| `_destructive-rules.nix`     | Canonical destructive command list + generators for deny rules            |
| `_gemini-policies.nix`       | Gemini CLI TOML safety policies (allow research, deny destructive)        |
| `_opencode-profiles.nix`     | Seven OpenCode profile names and their XDG config paths                   |
| `_opencode-theme.nix`        | Catppuccin Mocha theme definition for OpenCode TUI                        |
| `_file-templates.nix`        | Static agent/skill/definition templates for Claude and Gemini             |
| `_impeccable-commands.nix`   | Impeccable skill pack command definitions and renderer                    |

### Services & Runtime

| File                            | Purpose                                                               |
| ------------------------------- | --------------------------------------------------------------------- |
| `_aliases.nix`                  | Zsh alias generation for agent launchers and workflow combos          |
| `_workflow-prompts.nix`         | Aggregator — imports each `workflows/_*.nix` and exposes them as an attrset |
| `_services-systemd.nix`         | Systemd user services/timers: log cleanup, DB vacuum, CLI auto-update |
| `_services-shell-aliases.nix`   | Shell aliases for logging/analytics (ai-logs, ai-errors, ai-stats)    |
| `_mk-cli-autoupdate-script.nix` | Generates shell script for auto-updating a CLI binary via bun/npm    |
| `_agentmemory-runtime.nix`      | agentmemory npm service + MCP shim packaging                          |
| `_git-clone-update.nix`         | Generates Bash snippet for git clone/update under `~/.local/share/`   |
| `_herdr-mimo-plugin.nix`        | Vendored herdr integration plugin for MiMoCode (herdr has no mimo target) |

### Workflow Prompts (`workflows/`)

See `workflows/AGENTS.md` for per-file details. `_workflow-prompts.nix` is the sole importer.

---

## Conventions

- All files are plain Nix expressions taking explicit arguments and returning attrsets.
- Underscore-prefixed (`_*.nix`) to distinguish from import-hub modules.
- Never listed in import hubs — imported directly by consumers.
- Single source of truth pattern: `_models.nix` for model IDs, `_destructive-rules.nix` for blocked commands, `_formatters.nix` for tool/formatter mappings.

---

## Gotchas

- `_settings-builders.nix` imports `_mcp-transforms`, `_formatters`, and `_models` — changes propagate here.
- `_zai-filters.nix` imports `_zai-services.nix` directly; both must stay in sync.
- `_zai-env.nix` is imported by both `_aliases.nix` (for claude_glm) and `android-re/_launchers.nix`.
- `_gemini-policies.nix` imports `_destructive-rules.nix` directly.
- `_aliases.nix` and `android-re/_launchers.nix` both import `_models.nix`.
- `_workflow-prompts.nix` is the sole importer of `workflows/_*.nix` files — there is no `helpers/default.nix` import hub.
- `toHookPattern` in `_destructive-rules.nix` has special-case regex escaping for `rm -rf /`, `rm -rf ~`, `dd` — consider grep regex safety when adding commands.
