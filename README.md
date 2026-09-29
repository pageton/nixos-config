# NixOS System Configuration

[![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![Niri](https://img.shields.io/badge/Niri-Wayland-58A6FF?style=for-the-badge)](https://github.com/YaLTeR/niri)
[![Flakes](https://img.shields.io/badge/Flakes-Enabled-5277C3?style=for-the-badge)](https://nixos.wiki/wiki/Flakes)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

A modular, reproducible NixOS flake configuration managing multiple hosts (desktop and laptop) with Home-Manager integration.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Onboarding a New Machine](#onboarding-a-new-machine)
- [Project Structure](#project-structure)
- [Flake Inputs](#flake-inputs)
- [Deployment](#deployment)
- [Secrets Management](#secrets-management)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

---

## Overview

This repository contains a declarative NixOS configuration using flakes with the following features:

- **Multi-host support**: `desktop` and `thinkpad` (laptop)
- **Modular architecture**: Reusable NixOS and Home-Manager modules
- **Desktop environment**: Niri (Wayland) with Noctalia shell and Stylix theming
- **Security**: SOPS encrypted secrets, Mullvad VPN, Tor support
- **Development**: NVF (Neovim), Helix, language tooling (Go, Python)
- **Automation**: `just` commands for common tasks

### Supported Hosts

| Host       | Description | Key Features                                 |
| ---------- | ----------- | -------------------------------------------- |
| `desktop`  | Desktop PC  | Gaming (Gamescope), full desktop environment |
| `thinkpad` | Laptop      | NVIDIA GPU, power management (TLP)           |

---

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/pageton/nixos-config.git ~/System
cd ~/System

# Apply the configuration (runs full pipeline: lint, format, flake check, nh os switch, home-manager switch)
just all
```

### Onboarding a New Machine

1. **Clone the repo:**

```bash
git clone https://github.com/pageton/nixos-config.git ~/System
cd ~/System
```

2. **Create the host configuration:**

```bash
cd hosts
cp -r desktop myhost  # or thinkpad/server as template
```

3. **Copy the hardware configuration:**

```bash
cp /etc/nixos/hardware-configuration.nix hosts/myhost/
```

4. **Update personal settings in `shared/constants.nix`:**
   Edit `shared/constants.nix` to set your identity (name, email, GitHub handle, GPG signing key) and preferences (terminal, editor, fonts, keyboard layout, theme colors).

5. **Add the new host to `hosts/_inventory.nix`:**
   Open `hosts/_inventory.nix` and append your new host:

```nix
{
  hostname = "myhost";
  stateVersion = "26.05";
}
```

6. **Set your hostname:**

```bash
sudo hostnamectl set-hostname myhost
```

7. **Setup SOPS encryption key** (if not already done):

```bash
nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt
```

8. **Deploy the system:**

```bash
# For the new host (using nh)
nh os switch --flake ~/System#myhost

# For home-manager (using nh)
nh home switch --flake ~/System#sadiq@myhost

# Or use the just commands:
just nixos  # System rebuild
just home   # Home Manager only
```

---

## Project Structure

```
System/
├── flake.nix                    # Main flake definition
├── justfile                     # Task automation commands
├── .sops.yaml                   # SOPS encryption config
├── shared/                      # Cross-boundary shared Nix helpers
│   ├── constants.nix            # Single source of truth (user, fonts, colors, keyboard, ports)
│   ├── alias-helpers.nix        # Shared shell alias injection for zsh/bash
│   └── _*.nix                   # Secret-check and systemd-timer helpers
│
├── hosts/                       # Host-specific configurations
│   ├── _inventory.nix           # Host list (single source of truth for flake.nix)
│   ├── desktop/                 # Desktop PC configuration
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── modules/
│   ├── thinkpad/                # Laptop configuration
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   └── modules/
│
├── nixos/                         # Shared NixOS system configuration
│   ├── profiles/
│   │   └── common.nix             # Modules active on every host (the shared set)
│   └── modules/                   # Flat feature modules — imported = active
│       ├── base.nix               # Nix settings, overlays, locale, env, monitoring tools
│       ├── boot.nix               # GRUB + kernel
│       ├── users.nix              # User account + SSH keys
│       ├── sops.nix               # Secrets
│       ├── tuning.nix             # earlyoom, sysctl, PAM limits
│       ├── opsec.nix              # Session lock, NTS time, zram
│       ├── security.nix           # Kernel hardening, firewall, AIDE, AppArmor
│       ├── network.nix            # NetworkManager, resolved, sshd
│       ├── macchanger.nix         # MAC randomization
│       ├── validation.nix         # Conflict assertions
│       ├── audio.nix              # PipeWire + RNNoise
│       ├── bluetooth.nix          # BlueZ + Blueman
│       ├── nvidia.nix             # NVIDIA driver stack
│       ├── android.nix            # ADB / Android Studio
│       ├── desktop.nix            # Niri, Noctalia Greeter, portals, xkb
│       ├── browser-deps.nix       # Chromium / Puppeteer deps
│       ├── sandboxing.nix         # Firejail wrapped binaries
│       ├── nix-ld.nix             # Non-NixOS binaries
│       ├── tailscale.nix          # Mesh VPN (Mullvad-coexistence aware)
│       ├── tor.nix                # Tor SOCKS/DNS
│       ├── mullvad.nix            # Mullvad VPN (desktop)
│       ├── cloudflared.nix        # Cloudflare Tunnel (desktop)
│       ├── cloudflare-warp.nix    # WARP client (desktop)
│       ├── flatpak.nix            # Flathub
│       ├── syncthing.nix          # File sync
│       ├── glance/                # Dashboard (default.nix + settings.nix)
│       ├── netdata.nix            # Metrics (boot-deferred)
│       ├── scrutiny.nix           # Disk health (boot-deferred)
│       ├── loki.nix               # Log aggregation (boot-deferred)
│       ├── observability/         # Prometheus + Grafana (desktop, boot-deferred)
│       ├── gaming.nix             # Steam, gamescope, gamemode (desktop)
│       ├── virtualisation.nix     # Docker, VirtualBox, libvirt (desktop)
│       ├── vaultwarden.nix        # Password manager (desktop)
│       ├── web-re.nix             # Web RE tools (desktop)
│       └── amd-thermal.nix        # Ryzen thermal watchdog (desktop)
│
└── home/                        # Home-Manager user configuration
    ├── home.nix                 # Main Home-Manager entry point
    ├── assets/                  # Static assets (profile picture, etc.)
    ├── core/                    # Home base split (user, session, GTK, activation, desktop-entries)
    │
    ├── packages/                # User package definitions
    │   ├── cli.nix              # Command-line tools
    │   ├── applications.nix     # Desktop applications
    │   ├── development.nix      # Development tools
    │   ├── multimedia.nix       # Multimedia packages
    │   └── ...
    │
    ├── programs/                # Application configurations
    │   ├── terminal/            # Terminal, shell, and CLI tools
    │   │   ├── alacritty.nix    #   Alacritty terminal (default)
    │   │   ├── ghostty.nix      #   Ghostty terminal
    │   │   ├── shell.nix        #   Bash/Zsh, starship, tmux config
    │   │   └── ...
    │   ├── nvf/                 # NVF (Neovim)
    │   ├── languages/           # Language toolchains (Go, Python, Node.js)
    │   ├── ai/                  # AI coding agent CLIs (llm-agents.nix)
    │   ├── zen-browser/         # Zen Browser multi-profile setup
    │   ├── isolation/           # Application isolation wrappers
    │   └── ...                  # brave, discord, gpg, obs, spicetify, ssh, etc.
    │
    ├── desktop/                 # Desktop environment configs
    │   ├── niri/                # Niri session config
    │   ├── noctalia/            # Noctalia shell/bar/launcher
    │   ├── qt/                  # Qt Wayland integration
    │   ├── mime/                # MIME defaults
    │   └── udiskie/             # Auto-mount removable media
    │
    └── themes/                  # Theme configurations
        ├── stylix.nix           # Stylix theming engine
        ├── palette.nix          # Catppuccin Mocha color palette
        └── options.nix          # Theme option definitions
```

---

## Flake Inputs

This configuration uses the following flakes:

| Flake              | Purpose                                                                                                   |
| ------------------ | --------------------------------------------------------------------------------------------------------- |
| **nixpkgs**        | NixOS unstable packages                                                                                   |
| **nixpkgs-stable** | NixOS 26.05 stable packages                                                                               |
| **home-manager**   | User environment management                                                                               |
| **sops-nix**       | Secret management with age encryption                                                                     |
| **stylix**         | System theming (Catppuccin Mocha theme)                                                                   |
| **spicetify-nix**  | Spotify customization                                                                                     |
| **niri**           | Niri compositor module/overlay (does NOT follow nixpkgs — pinned mesa version required for compatibility) |
| **noctalia**       | Noctalia shell integration                                                                                |
| **nixcord**        | Discord theming                                                                                           |
| **nvf**            | Neovim configuration framework                                                                            |
| **llm-agents**     | AI agent CLIs and desktop apps (Codex, OpenCode, Pi, Herdr, ZCode, …)                                     |

---

## Deployment

This repository uses [`just`](https://github.com/casey/just) as a command runner to simplify common tasks.

### Daily Workflow

```bash
just status        # desired vs saved vs active generations (eval only)
just preview       # build + diff the system, save the reviewed generation
just switch        # activate exactly that saved system build
just home-preview  # build + diff Home-Manager, review managed-file changes
just home-switch   # activate exactly that saved Home-Manager generation
```

`just switch` and `just home-switch` never re-evaluate or rebuild: they only
activate the generation saved by the matching `*-preview` command, so what you
reviewed is what you get. Use `just nixos` / `just home` (nh) when you want a
direct rebuild-and-switch instead.

### Essential Commands

| Command                   | Description                                                                      |
| ------------------------- | -------------------------------------------------------------------------------- |
| `just`                    | List all available commands                                                      |
| `just all`                | **Run full pipeline**: lint, format, flake check, nixos, home                     |
| `just nixos`              | Rebuild and switch current host (`--hostname $(hostname)`) with faster nh flags  |
| `just nixos <host>`       | Rebuild and switch a specific host profile (e.g. `just nixos desktop`)           |
| `just nixos-fast`         | Faster switch path (`NH_NO_VALIDATE=1`, no NOM) for iterative changes            |
| `just home`               | Apply Home-Manager configuration using nh with lockfile-write disabled           |
| `just status`             | Show desired vs saved vs active generations (eval only, no build)                |
| `just preview`            | Build + diff system closure vs `/run/current-system`, save generation            |
| `just switch`             | Activate the saved system preview (hostname guard; run `just preview`)           |
| `just home-preview`       | Build + diff Home-Manager, report managed-file changes, save generation          |
| `just home-switch`        | Activate the saved Home-Manager preview (run `just home-preview` first)          |
| `just format`             | Format all `.nix` (nixfmt) and `.sh` (shfmt) files                               |
| `just lint`               | Lint `.nix` with statix; `.sh` with shellcheck + shfmt                           |
| `just check`              | Evaluate full flake outputs with `nix flake check`                               |
| `just qa`                 | Local QA (lint + flake check)                                                     |
| `just update`             | Update all flake inputs                                                          |
| `just update-pkgs`        | Update nixpkgs only                                                              |
| `just update-pkgs-stable` | Update stable nixpkgs                                                            |
| `just clean`              | Clean up old generations and optimize store using **nh**                         |

### Manual Rebuild (without just)

```bash
# NixOS system rebuild
sudo nixos-rebuild switch --flake .#desktop

# Home-Manager switch
home-manager switch --flake .#sadiq@desktop

# Using nh
nh os switch . -- hostname desktop
nh home switch . -- hostname desktop
```

---

## Secrets Management

This configuration uses [SOPS](https://github.com/Mic92/sops-nix) with `age` encryption for secrets.

### Quick Start

```bash
# Setup age key (if not already done)
nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt

# View current secrets
just sops-view

# Edit secrets
just sops-edit
# NOTE: If interrupted, a decrypted file may remain on disk.
# The .gitignore pattern *-decrypted.* prevents accidental commits.

# Add single secret
# WARNING: The value will be stored in shell history.
# For sensitive values, use `just sops-edit` instead.
just secrets-add github_token ghp_your_token_here
```

### Available Commands

| Command                      | Purpose                             |
| ---------------------------- | ----------------------------------- |
| `just sops-view`             | View decrypted secrets              |
| `just sops-edit`             | Edit secrets (opens VS Code)        |
| `just secrets-add key value` | Add single secret                   |
| `just sops-decrypt`          | Decrypt to file for manual editing  |
| `just sops-encrypt`          | Encrypt file back to secrets        |
| `just sops-key`              | Show public age key                 |

### Structure

```
nixos/modules/sops.nix
secrets/secrets.yaml
```

### Security Notes

- Secrets are encrypted at rest using age encryption
- Private keys are stored in `~/.config/sops/age/keys.txt`
- Never commit private keys or decrypted secrets to Git
- Use `just sops-edit` for most editing (automatic encrypt/decrypt)

### Using Secrets in Configuration

```nix
# In any Nix file
sops.secrets.mysecret = {
  owner = config.users.users.sadiq.name;
};

# Access in scripts or services
environment.variables.MY_SECRET = config.sops.placeholder.mysecret;
```

---

## Configuration

### Adding a New Host

1. Create host directory:

```bash
mkdir -p hosts/myhost/modules
```

2. Create `configuration.nix`:

```nix
{ config, inputs, hostname, stateVersion, pkgsStable, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../nixos/modules
    ./modules/default.nix
  ];

  # Host-specific settings
  networking.hostName = "myhost";
}
```

3. Create `hardware-configuration.nix`:

```bash
sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/myhost/hardware-configuration.nix
```

4. Add to `hosts/_inventory.nix`:

```nix
{
  hostname = "myhost";
  stateVersion = "25.11";
}
```

### Adding NixOS Modules

Modules are plain NixOS configuration — no custom options, no enable flags.
A module is active because a host (or the shared profile) imports it.

1. Create a flat module in `nixos/modules/`:

```nix
# nixos/modules/my-module.nix
{ pkgs, ... }:
{
  # Your configuration here
  environment.systemPackages = [ pkgs.hello ];
}
```

2. Import it where it belongs:

```nix
# nixos/profiles/common.nix        — if every host needs it
# hosts/desktop/configuration.nix  — if only one host needs it
{
  imports = [
    # ... existing modules ...
    ../../nixos/modules/my-module.nix
  ];
}
```

Rules of thumb:

- Machine-specific values (bus IDs, thresholds, kernel params) go in
  `hosts/<name>/`, not in shared modules.
- Cross-module wiring reads real NixOS options
  (e.g. `config.services.mullvad-vpn.enable`), not custom toggles.
- Only declare a custom option when you truly need parameterization,
  and scope it tightly.

3. Run `just check` to verify the configuration evaluates.

### Adding Home-Manager Programs

1. Create program directory in `home/programs/`:

```bash
mkdir home/programs/myprogram
```

2. Create `default.nix`:

```nix
{ config, lib, ... }:
{
  programs.myprogram = {
    enable = true;
    # Settings
  };
}
```

3. Import in `home/programs/default.nix`

### Adding Packages

Edit the appropriate file in `home/packages/`:

```nix
# home/packages/cli.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Add packages here
    my-new-package
  ];
}
```

### Host-Specific Package Loading

The configuration uses hostname-based conditional loading:

```nix
# In home/packages or home/programs
config = lib.mkIf (hostname == "desktop") {
  # Desktop-only packages
};
```

---

## Features

### Desktop Environment

- **Compositor**: Niri (Wayland)
- **Shell**: DankMaterialShell (bar, launcher, control center, notifications)
- **Theme**: Catppuccin Mocha via Stylix
- **Screen Locker**: DankMaterialShell lock screen with native idle handling
- **Clipboard stack**: DankMaterialShell history + wl-clip-persist

### Development

- **Neovim**: NVF configuration with LSP
- **Editor**: Helix
- **Languages**: Go, Python, Node.js support
- **Tools**: Git, lazydocker, gh

### Security & Privacy

- **VPN**: Mullvad, Tailscale support
- **Anonymity**: Tor relay
- **Secrets**: SOPS encrypted with age
- **Firewall**: Configured via networking module

### Gaming

- **Gamescope**: For Steam games
- **optimizations**: GPU drivers, performance tweaks

---

## Troubleshooting

### Build Errors

```bash
# Evaluate flake outputs
just check

# Lint files
just lint

# View build logs
sudo nixos-rebuild switch --flake .#desktop --show-trace
```

### Secrets Issues

```bash
# Check if age key exists
just sops-key

# Regenerate key
nix shell nixpkgs#age -c age-keygen -o ~/.config/sops/age/keys.txt

# Verify .sops.yaml has correct age key
cat .sops.yaml
```

### Hostname Mismatch

```bash
# Check current hostname
hostname

# Set correct hostname
sudo hostnamectl set-hostname desktop
```

### Nix Store Issues

```bash
# Clean and optimize
just clean

# Manual cleanup
nix-collect-garbage -d
nix store optimise
```

### Flake Lock Issues

```bash
# Update flake lock
nix flake update

# Rebuild after update
just all
```

### Home-Manager Specific Issues

```bash
# Check Home-Manager config
home-manager switch --flake .#sadiq@desktop --show-trace

# Expire old generations
home-manager expire-generations "-7 days"
```

---

## Additional Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home-Manager Manual](https://nix-community.github.io/home-manager/)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/)
- [Niri Documentation](https://github.com/YaLTeR/niri/wiki)
- [SOPS-Nix](https://github.com/Mic92/sops-nix)

---

## License

MIT License - see [LICENSE](LICENSE) for details.
