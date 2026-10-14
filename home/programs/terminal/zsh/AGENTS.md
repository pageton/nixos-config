# Zsh Configuration

Zsh shell with Oh My Zsh framework — aliases, functions, config, and local variable overrides.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Imports all zsh sub-modules |
| `aliases.nix` | Shell aliases (ls replacements, git shortcuts, system commands) |
| `functions.nix` | Custom shell functions |
| `config.nix` | Zsh options, Oh My Zsh plugins, keybindings, completions |
| `local-vars.nix` | Local/session environment variables |

## Conventions

- Aliases and functions are separate files for maintainability
- `config.nix` handles Oh My Zsh plugin list and zsh options
- Shared aliases come from `shared/alias-helpers.nix` (injected at flake level)

## Dependencies

- **Imports**: `shared/alias-helpers.nix`, Oh My Zsh plugins
- **Imported by**: `home/programs/terminal/default.nix`
