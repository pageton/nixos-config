# AI Agent Claude Hooks

Claude Code hooks, permission rules, and session configuration for the AI agent orchestration layer.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Aggregates all Claude sub-modules |
| `_hooks.nix` | Core hook definitions |
| `_hooks-helpers.nix` | Shared helper expressions for hooks |
| `_hooks-pre-tool-use.nix` | Pre-tool-use hook handlers |
| `_hooks-post-tool-use.nix` | Post-tool-use hook handlers |
| `_hooks-session.nix` | Session lifecycle hooks |
| `_permission-rules.nix` | Permission rule definitions for Claude Code |

## Conventions

- Files prefixed with `_` are internal helpers, not standalone modules
- Hooks are JavaScript modules executed by Claude Code during tool use
- Permission rules control which tools/actions are allowed without confirmation

## Dependencies

- **Imported by**: `home/programs/ai-agents/config/default.nix`
