# Home-Manager Programs

Application and tool configurations — each program gets its own module (flat `.nix` file or subdirectory with `default.nix`).

## Files

| File/Dir | Purpose |
|----------|---------|
| `default.nix` | Import hub: 6 subdirs + 10 flat files |
| `ai-agents/` | AI coding agents (Claude Code, Codex, OpenCode, OMP, ZCode) — config, hooks, services, activation |
| `languages/` | Language toolchains (Go, Python, JS/Node), LSP servers, mise version manager |
| `terminal/` | Terminal emulator (Alacritty), shell (Zsh), multiplexer (Zellij), 20+ CLI tools |
| `nvf/` | Neovim via NVF framework |
| `librewolf/` | LibreWolf browser with multi-profile proxy setup |
| `isolation/` | Wayland browser sandbox wrappers |
| `brave.nix` | Brave browser with Wayland flags and extensions |
| `chromium.nix` | Chromium launch wrapper with Wayland flags |
| `discord.nix` | Discord/Vesktop theming via nixcord |
| `gpg.nix` | GPG key management and agent |
| `obs.nix` | OBS Studio configuration |
| `spicetify.nix` | Spotify customization via spicetify-nix |
| `ssh.nix` | SSH client configuration |
| `tailscale.nix` | Tailscale VPN packages |
| `thunar.nix` | Thunar file manager custom actions |
| `activitywatch.nix` | ActivityWatch time tracking |

## Directory Structure

```
home/programs/
├── default.nix          # Import hub for all programs
├── ai-agents/           # AI coding agent orchestration
├── languages/           # Language toolchains + LSP servers
├── terminal/            # Terminal, shell, multiplexer, CLI tools
├── nvf/                 # Neovim via NVF framework
├── librewolf/           # LibreWolf browser
├── isolation/           # Browser sandbox wrappers
├── brave.nix            # Brave browser config
├── chromium.nix         # Chromium launch wrapper
├── discord.nix          # Discord theming
├── gpg.nix              # GPG key management
├── obs.nix              # OBS Studio
├── spicetify.nix        # Spotify customization
├── ssh.nix              # SSH client
├── tailscale.nix        # Tailscale VPN
├── thunar.nix           # Thunar file manager
└── activitywatch.nix    # ActivityWatch time tracking
```

## Conventions

- Subdirectories (ai-agents, languages, terminal, nvf, librewolf, isolation) contain `default.nix` that imports their sub-modules
- Flat `.nix` files are single-concern application configs
- Avoid new flat files for multi-file modules — create a subdirectory with `default.nix`

## Dependencies

- **Imported by**: `home/home.nix` (via `./programs`)
