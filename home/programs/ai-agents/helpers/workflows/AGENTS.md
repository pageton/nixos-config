# AI Agent Workflows

Pure-Nix workflow templates for common AI agent tasks. Each file is a plain expression (not a Home Manager module) returning an attrset that defines a workflow.

## Files

| File | Purpose |
|------|---------|
| `_shared.nix` | Shared helper expressions used across all workflows |
| `_bugfix-root-cause.nix` | Root cause analysis workflow for bug fixes |
| `_build-performance.nix` | Build performance diagnosis workflow |
| `_commit-split.nix` | Commit splitting workflow for clean git history |
| `_dependency-upgrade.nix` | Dependency upgrade workflow with compatibility checks |
| `_markdown-sync.nix` | Documentation markdown sync workflow |
| `_refactor-maintainability.nix` | Refactoring workflow focused on maintainability |
| `_runtime-performance.nix` | Runtime performance analysis workflow |
| `_security-audit.nix` | Security audit workflow template |

## Conventions

- Files prefixed with `_` are internal expressions
- Each workflow is a pure Nix attrset defining prompts, tools, and steps
- `_shared.nix` provides common builders and helpers

## Dependencies

- **Imported by**: `home/programs/ai-agents/helpers/default.nix`
