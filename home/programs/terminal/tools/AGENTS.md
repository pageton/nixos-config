# CLI Tool Configurations

Declarative configurations for 20+ CLI tools. Each file configures a single tool via its Home-Manager program module. All imported by `tools/default.nix`.

## Files

| File | Tool | Purpose |
|------|------|---------|
| `atuin.nix` | Atuin | Shell history with full-text search and sync |
| `bat.nix` | bat | Syntax-highlighting cat replacement |
| `btop.nix` | btop | System monitor with GPU support |
| `cava.nix` | cava | Audio visualizer |
| `carapace.nix` | Carapace | Multi-shell argument completions |
| `eza.nix` | eza | Modern ls replacement with icons |
| `fzf.nix` | fzf | Fuzzy finder with Zsh integration |
| `gh.nix` | GitHub CLI | Declarative gh settings |
| `git/` | Git | Difftastic, GPG signing, global hooks |
| `htop.nix` | htop | Process viewer (legacy — btop preferred) |
| `lazygit.nix` | lazygit | Git TUI |
| `mpv.nix` | mpv | Media player with Vim keybindings |
| `starship.nix` | Starship | Cross-shell prompt |
| `yazi.nix` | yazi | Terminal file manager |
| `zathura.nix` | zathura | PDF viewer |
| `zoxide.nix` | zoxide | Smart directory jumper |

## Conventions

- One file per tool, named after the tool's package/program name
- Each file uses the corresponding `programs.<tool>` Home-Manager option
- `git/` is a subdirectory due to multiple files (config, hooks, difftastic)

## Dependencies

- **Imported by**: `home/programs/terminal/default.nix` → `tools/default.nix`
- **Cross-references**: fzf integrates with zsh; starship/zoxide/atuin are zsh plugins
