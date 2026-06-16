# AI Agent Configuration Hub

Central registry for AI agent defaults, MCP servers, model definitions, and Claude Code settings.

---

## Overview

This directory holds the **data layer** for `programs.aiAgents`. While `options.nix` (parent) defines *what* can be configured, this directory defines *what the values are*:

1. **`defaults.nix`** — Enablement flags, global instructions, skill set selection
2. **`mcp-servers.nix`** — Shared MCP server definitions (Context7, GitHub, Semgrep, Chrome DevTools, PyGhidra)
3. **`mcp-servers-android-re.nix`** — Android RE agent-specific servers (PyGhidra, APKTool)
4. **`mcp-servers-web-re.nix`** — Web RE agent-specific servers (placeholder)
5. **`claude/`** — Claude Code permissions, lifecycle hooks, and extra settings
6. **`models/`** — Model/provider registries for each agent runtime

---

## Directory Structure

```
config/
├── default.nix                   # Import hub
├── defaults.nix                  # Enablement, global instructions, skill defaults
├── global-instructions.md        # Global instructions text (read by defaults.nix)
├── _skills.nix                  # Skill installations and omissions
├── mcp-servers.nix              # Shared MCP server definitions + logging
├── mcp-servers-android-re.nix   # Android RE agent-specific MCP servers
├── mcp-servers-web-re.nix       # Web RE agent-specific MCP servers
├── claude/                       # Claude Code configuration
│   ├── default.nix              # Import hub (permissions, hooks, settings)
│   ├── _hooks.nix               # Lifecycle hooks aggregation
│   ├── _hooks-helpers.nix       # Shared hook constructors
│   ├── _hooks-pre-tool-use.nix  # Pre-tool-use safety hooks
│   ├── _hooks-post-tool-use.nix  # Post-tool-use auto-format hooks
│   ├── _hooks-session.nix        # Session lifecycle hooks
│   └── _permission-rules.nix    # Claude allow/deny rules
└── models/                       # Model/provider registries
    ├── default.nix              # Import hub + shared toggles
    ├── codex.nix                # Codex CLI configuration
    ├── opencode.nix             # OpenCode configuration (agents, LSP, providers)
```

---

## Conventions

### File Naming
- **`default.nix`** — Always the import hub for that directory
- **`_*.nix`** — Helper files imported by other files, never listed in import hubs
- **`mcp-servers-*.nix`** — Agent-specific MCP server definitions (not shared globally)

### MCP Server Definitions
Shared MCP servers go in `mcp-servers.nix`. Agent-specific servers (Android RE, Web RE) go in dedicated files and are assigned to `programs.aiAgents.<agent>McpServers`, not the shared `mcpServers`.

### Skill Registry
`_skills.nix` is the single source of truth for skill installations. It exports a list of `{ repo, skill }` attrsets consumed by `defaults.nix`.

### Model Configuration
Each agent runtime has its own file in `models/`. The `default.nix` import hub wires them together. Model defaults are set in `helpers/_models.nix` (parent helpers directory).

---

## Key Files

| File | Purpose |
|------|---------|
| `defaults.nix` | Sets `enable`, `globalInstructions`, `skills`, and sub-agent toggles |
| `mcp-servers.nix` | Defines shared MCP servers with placeholder-based secret injection |
| `mcp-servers-android-re.nix` | PyGhidra + APKTool MCP for Android RE workflows |
| `mcp-servers-web-re.nix` | Placeholder for future web RE MCP servers |
| `claude/default.nix` | Claude Code model, env vars, permissions, hooks, extraSettings |
| `models/default.nix` | Import hub for all agent model configurations |

---

## Notes

- **Secrets**: MCP server API keys use placeholders (`__KEY_PLACEHOLDER__`) patched at activation time via `activation/secrets.nix`
- **Java/Native deps**: PyGhidra MCP needs `LD_LIBRARY_PATH` and JDK on `PATH` — handled via wrapper scripts in `mcp-servers.nix`
- **Claude hooks**: Heavy use of `jq` and `grep` in lifecycle hooks for auto-formatting and destructive command detection
