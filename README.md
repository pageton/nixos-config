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

| Host | Description | Key Features |
|------|-------------|--------------|
| `desktop` | Desktop PC | Gaming (Gamescope), full desktop environment |
| `thinkpad` | Laptop | NVIDIA GPU, power management (TLP) |

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

4. **Update personal settings in `shared/constants.nix`:**
Edit `shared/constants.nix` to set your identity (name, email, GitHub handle, GPG signing key) and preferences (terminal, editor, fonts, keyboard layout, theme colors).

5. **Add the new host to `hosts/_inventory.nix`:**
Open `hosts/_inventory.nix` and append your new host:
```nix
{
  hostname = "myhost";
  stateVersion = "25.11";
}
```

6. **Set your hostname:**
```bash
sudo hostnamectl set-hostname myhost
```

7. **Setup SOPS encryption key** (if not already done):
```bash
just sops-setup
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
│   ├── _option-helpers.nix      # Typed option constructors (mkBoolOption, mkStrOption, etc.)
│   ├── _alias-helpers.nix       # Shared shell alias injection for zsh/bash
│   └── _secret-loader.nix       # Shell function to load SOPS secrets from /run/secrets/
├── scripts/                     # Repository-level audit and lab scripts
│   ├── build/                   # modules/security/performance audit scripts
│   ├── ai/                      # AI agent launchers, inventory, and log analysis
│   ├── apps/                    # Desktop app wrappers (browser-select, youtube-mpv, etc.)
│   ├── system/                  # System health report collectors
│   ├── sops/                    # SOPS editing helpers
│   └── lib/                     # Shared shell helpers (logging, testing, AWK)
│
├── hosts/                       # Host-specific configurations
│   ├── _inventory.nix           # Host list (currently unused — see file header)
│   ├── desktop/                 # Desktop PC configuration
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   ├── local-packages.nix
│   │   └── modules/
│   ├── thinkpad/                # Laptop configuration
│   │   ├── configuration.nix
│   │   ├── hardware-configuration.nix
│   │   ├── local-packages.nix
│
├── nixos/modules/               # Shared NixOS system modules (two-level pattern)
│   ├── default.nix              # Root loader — imports category directories
│   ├── core/                    # Boot, Nix daemon, users, SOPS, timezone, locale, stability
│   │   └── default.nix          #   Imports flat .nix files from parent dir
│   ├── hardware/                # Audio, Bluetooth, GPU, input, power, thermal
│   ├── desktop/                 # Niri, SDDM, X11 disabled, XDG portals
│   ├── network/                 # NetworkManager, DNSCrypt, Mullvad, Tailscale, Tor
│   ├── security-stack/          # Kernel hardening, Firejail, OpenSnitch, MAC randomization
│   ├── apps/                    # Browser deps, Flatpak, Gaming, KDE Connect, Syncthing
│   ├── virtualization/          # Docker, VirtualBox, libvirt, Waydroid, nix-ld
│   ├── observability/           # Monitoring, Netdata, Scrutiny, Glance, Loki
│   ├── performance/             # Boot optimization
│   ├── maintenance/             # Cleanup timers, Restic backup, nh
│   │
│   ├── bootloader.nix           # (flat files imported by category default.nix)
│   ├── security.nix             # Kernel/sysctl hardening, firewall, AIDE, Chrony, AppArmor
│   └── ...                      # Other system modules
│
└── home/                        # Home-Manager user configuration
    ├── home.nix                 # Main Home-Manager entry point
    ├── modules/                 # Home base split (core/session/ui/activation)
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
    │   ├── niri/                # Niri session config
    │   ├── noctalia/            # Noctalia shell/bar/launcher
    │   ├── qt/                  # Qt Wayland integration
    │   ├── mime/                # MIME defaults
    │   └── ...
    │
    ├── themes/                  # Theme configurations
    │   └── catppuccin.nix     # Catppuccin Mocha + Stylix theming
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
| **stylix** | System theming (Catppuccin Mocha theme) |
| **spicetify-nix** | Spotify customization |
| **niri** | Niri compositor module/overlay (does NOT follow nixpkgs — pinned mesa version required for compatibility) |
| **noctalia** | Noctalia shell integration |
| **nixcord** | Discord theming |
| **nvf** | Neovim configuration framework |
| **ghgrab** | GitHub release downloader utility |


---

## Deployment

This repository uses [`just`](https://github.com/casey/just) as a command runner to simplify common tasks.

### Daily Workflow

### Git Hooks

The repository includes pre-commit and pre-push hooks for automated quality checks:

```bash
# Install pre-commit hook (runs modules-check + lint + format before each commit)
ln -sf ../../scripts/build/pre-commit-hook.sh .git/hooks/pre-commit

# Install pre-push hook (enforces GPG-signed commits)
ln -sf ../../scripts/build/pre-push-hook.sh .git/hooks/pre-push
```

### Essential Commands

| Command | Description |
|---------|-------------|
| `just` | List all available commands |
| `just all` | **Run full pipeline**: modules, lint, format, security, flake check, nixos, home |
| `just nixos` | Rebuild and switch current host (`--hostname $(hostname)`) with faster nh flags |
| `just nixos <host>` | Rebuild and switch a specific host profile (e.g. `just nixos desktop`) |
| `just nixos-fast` | Faster switch path (`NH_NO_VALIDATE=1`, no NOM) for iterative changes |
| `just home` | Apply Home-Manager configuration using nh with lockfile-write disabled |
| `just format` | Format all `.nix` files with `nixfmt` |
| `just lint` | Lint all `.nix` files with `statix` + bash shellcheck |
| `just modules` | Check for missing module imports (**critical before commits**) |
| `just security` | Scan for risky security patterns and plaintext secret leaks |
| `just perf` | Print boot/session performance diagnostics |
| `just hardening` | Run `systemd-analyze security` report on core services |
| `just check` | Evaluate full flake outputs with `nix flake check` |
| `just eval-audit` | Measure eval time for all host nixos/home outputs |
| `just eval-current` | Measure eval time for current host outputs only |
| `just qa` | Full local QA (modules + security + check + eval-audit) |
| `just qa-fast` | Fast local QA (modules + security + eval-current) |
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
# NOTE: If interrupted, a decrypted file may remain on disk.
# The .gitignore pattern *-decrypted.* prevents accidental commits.

# Add single secret
# WARNING: The value will be stored in shell history.
# For sensitive values, use `just sops-edit` instead.
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

1. Create module file in `nixos/modules/` (flat file alongside existing ones):
```nix
# nixos/modules/my-module.nix
{ config, lib, pkgs, ... }:
{
  # Define options under mySystem.* for per-host opt-in
  options.mySystem.myModule = {
    enable = lib.mkEnableOption "my custom module";
  };

  config = lib.mkIf config.mySystem.myModule.enable {
    # Your configuration here
  };
}
```

2. Import it from the appropriate category `default.nix` (e.g., `nixos/modules/core/default.nix`):
```nix
{
  imports = [
    # ... existing modules ...
    ../my-module.nix
  ];
}
```

3. Enable it in the host configuration (e.g., `hosts/desktop/configuration.nix`):
```nix
mySystem.myModule.enable = true;
```

4. Run `just modules` to verify the import is detected.

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
- **Shell**: Noctalia (bar, launcher, control center, notifications)
- **Theme**: Catppuccin Mocha via Stylix
- **Screen Locker**: swaylock + Noctalia lock integration
- **Clipboard stack**: wl-paste + cliphist + wl-clip-persist

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
- [Niri Documentation](https://github.com/YaLTeR/niri/wiki)
- [SOPS-Nix](https://github.com/Mic92/sops-nix)

---

## License

MIT License - see [LICENSE](LICENSE) for details.
