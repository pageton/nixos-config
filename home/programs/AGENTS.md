# Home-Manager Programs

Top-level Home-Manager program configuration hub. Contains standalone `.nix` files for individual programs and subdirectories for complex multi-file configurations.

## Architecture

```
home/programs/
├── default.nix          # Imports all subdirectories and standalone .nix files
├── ai-agents/           # AI agent orchestration (has AGENTS.md)
├── terminal/            # Shell, terminal, CLI tools (has AGENTS.md)
├── nvf/                 # Neovim via NVF framework
├── zen-browser/         # Multi-profile browser with SOCKS5 proxies
├── languages/           # Go, Python, JS/Node, LSP servers, mise
├── isolation/           # Wayland browser sandbox wrappers
├── brave.nix            # Brave browser with proxy
├── discord.nix          # Discord/Vesktop theming (nixcord)
├── gpg.nix              # GPG key management and agent
├── obs.nix              # OBS Studio configuration
├── spicetify.nix        # Spotify customization (spicetify-nix)
├── ssh.nix              # SSH client configuration
├── tailscale.nix        # Tailscale VPN packages
├── thunar.nix           # Thunar file manager custom actions
├── t3code.nix           # T3 Code AI editor
└── activitywatch.nix    # ActivityWatch time tracking
```

## Subdirectories with AGENTS.md

- `ai-agents/` — Multi-provider AI agent orchestration
- `terminal/` — Zsh, Alacritty, Zellij, 20+ CLI tools

## Conventions

- Standalone `.nix` file for simple program configs (single file is sufficient)
- Subdirectory for complex configs requiring multiple files (e.g., ai-agents, terminal, nvf)
- Each subdirectory has its own `default.nix` as the import entry point

## Dependencies

- **Imported by**: `home/home.nix`
- **Receives**: `inputs`, `pkgs`, `pkgsStable`, `constants` via specialArgs
