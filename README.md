# NixOS System Configuration

[![NixOS](https://img.shields.io/badge/NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)](https://nixos.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-58A6FF?style=for-the-badge&logo=hyprland&logoColor=white)](https://hyprland.org)
[![Flakes](https://img.shields.io/badge/Flakes-Enabled-5277C3?style=for-the-badge)](https://nixos.wiki/wiki/Flakes)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

A modular, reproducible NixOS flake configuration managing multiple hosts (desktop, laptop, and server) with Home-Manager integration.

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

- **Multi-host support**: `desktop`, `thinkpad` (laptop), and `server`
- **Modular architecture**: Reusable NixOS and Home-Manager modules
- **Desktop environment**: Hyprland (Wayland) with Catppuccin theming
- **Security**: SOPS encrypted secrets, Mullvad VPN, Tor support
- **Development**: NVF (Neovim), Helix, language tooling (Go, Python)
- **Automation**: `just` commands for common tasks

### Supported Hosts

| Host | Description | Key Features |
|------|-------------|--------------|
| `desktop` | Desktop PC | Gaming (Gamescope), full desktop environment |
| `thinkpad` | Laptop | NVIDIA GPU, power management (TLP) |
| `server` | Server | Minimal, no desktop environment |

---

## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/pageton/nixos-config.git ~/System
cd ~/System

# Apply the configuration (runs full pipeline: modules check, lint, format, nh os switch, home-manager switch)
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

4. **Add the new host to `flake.nix`:**
Open `flake.nix` and add your new host to the `hosts` list:
```nix
hosts = [
  # ... existing hosts ...
  {
    hostname = "myhost";
    stateVersion = "25.11";
  }
];
```

5. **Set your hostname:**
```bash
sudo hostnamectl set-hostname myhost
```

6. **Setup SOPS encryption key** (if not already done):
```bash
just sops-setup
```

7. **Deploy the system:**
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
│
├── hosts/                       # Host-specific configurations
│   ├── desktop/                 # Desktop PC configuration
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   ├── local-packages.nix
│   │   └── modules/
│   ├── thinkpad/                # Laptop configuration
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   ├── local-packages.nix
│   │   └── modules/
│   └── server/                  # Server configuration
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       └── disk-config.nix
│
├── nixos/modules/               # Shared NixOS system modules
│   ├── default.nix              # Module loader
│   ├── audio.nix                # PipeWire audio
│   ├── bluetooth.nix            # Bluetooth support
│   ├── bootloader.nix           # System boot loader
│   ├── gaming.nix               # Gaming optimizations
│   ├── graphics.nix             # Graphics drivers
│   ├── hyprland.nix             # Hyprland WM
│   ├── networking.nix           # Network configuration
│   ├── security.nix             # Security settings
│   └── ...                      # Other system modules
│
└── home/                        # Home-Manager user configuration
    ├── home.nix                 # Main Home-Manager entry point
    │
    ├── packages/                # User package definitions
    │   ├── cli.nix              # Command-line tools
    │   ├── applications.nix     # Desktop applications
    │   ├── development.nix      # Development tools
    │   ├── fonts.nix            # Font packages
    │   └── ...
    │
    ├── programs/                # Application configurations
    │   ├── nvf/                 # NVF (Neovim)
    │   ├── helix/               # Helix editor
    │   ├── shell/               # Zsh configuration
    │   ├── languages/           # Language tooling
    │   └── ...
    │
    ├── system/                  # Desktop environment configs
    │   ├── hyprland/            # Hyprland settings
    │   ├── hyprlock/            # Screen locker
    │   ├── hyprpanel/           # Panel widget
    │   ├── wofi/                # App launcher
    │   └── ...
    │
    ├── themes/                  # Theme configurations
    │   └── catppucin.nix        # Catppuccin + Stylix
    │
    ├── secrets/                 # Encrypted secrets
    │   ├── default.nix
    │   └── secrets.yaml
    │
    └── scripts/                 # User scripts
        ├── ai/                  # AI helper scripts
        ├── build/               # Build helpers
        └── ...
```

---

## Flake Inputs

This configuration uses the following flakes:

| Flake | Purpose |
|-------|---------|
| **nixpkgs** | NixOS unstable packages |
| **nixpkgs-stable** | NixOS 25.11 stable packages |
| **home-manager** | User environment management |
| **sops-nix** | Secret management with age encryption |
| **stylix** | System theming (Catppuccin theme) |
| **spicetify-nix** | Spotify customization |
| **hyprpanel** | Hyprland panel widget |
| **zen-browser** | Privacy-focused web browser |
| **nixcord** | Discord theming |
| **vicinae** | IPC utility for Hyprland |
| **nvf** | Neovim configuration framework |
| **disko** | Disk management for NixOS |

---

## Deployment

This repository uses [`just`](https://github.com/casey/just) as a command runner to simplify common tasks.

### Daily Workflow

### Essential Commands

| Command | Description |
|---------|-------------|
| `just` | List all available commands |
| `just all` | **Run full pipeline**: modules check, lint, format, nh os switch, home-manager switch |
| `just nixos` | Rebuild and switch NixOS configuration using **nh** (modern Nix Helper) |
| `just home` | Apply Home-Manager configuration using **nh** (safe, user-level only) |
| `just format` | Format all `.nix` files with `nixfmt` |
| `just lint` | Lint all `.nix` files with `statix` + bash shellcheck |
| `just modules` | Check for missing module imports (**critical before commits**) |
| `just update` | Update all flake inputs |
| `just update-pkgs` | Update nixpkgs only |
| `just update-pkgs-stable` | Update stable nixpkgs |
| `just clean` | Clean up old generations and optimize store using **nh** |

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
just sops-setup

# View current secrets
just sops-view

# Edit secrets
just sops-edit

# Add single secret
just secrets-add github_token ghp_your_token_here
```

### Available Commands

| Command | Purpose |
|---------|---------|
| `just sops-view` | View decrypted secrets |
| `just sops-edit` | Edit secrets (opens VS Code) |
| `just secrets-add key value` | Add single secret |
| `just sops-decrypt` | Decrypt to file for manual editing |
| `just sops-encrypt` | Encrypt file back to secrets |
| `just sops-key` | Show public age key |
| `just sops-setup` | Setup new age key |
| `just setup-keys` | Setup SSH and GPG keys from secrets |

### Structure

```
home/secrets/
├── default.nix      # SOPS module configuration
└── secrets.yaml     # Encrypted secrets file
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

4. Add to `flake.nix` hosts list:
```nix
hosts = [
  # ... existing hosts ...
  {
    hostname = "myhost";
    stateVersion = "25.11";
  }
];
```

### Adding NixOS Modules

1. Create module file in `nixos/modules/`:
```nix
# nixos/modules/my-module.nix
{ config, pkgs, ... }:
{
  # Your configuration here
}
```

2. Import in `nixos/modules/default.nix`:
```nix
[
  # ... existing modules ...
  ./my-module.nix
]
```

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

- **Window Manager**: Hyprland (Wayland)
- **Panel**: Hyprpanel with system monitoring
- **Launcher**: Wofi
- **Theme**: Catppuccin (system-wide via Stylix)
- **Screen Locker**: Hyprlock
- **Notification**: Dunst

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
# Check for missing modules
just modules

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
just sops-setup

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
- [Hyprland Wiki](https://wiki.hyprland.org/)
- [SOPS-Nix](https://github.com/Mic92/sops-nix)

---

## License

MIT License - see [LICENSE](LICENSE) for details.
