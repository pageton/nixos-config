# AGENTS.md — NixOS System Configuration

## Role

Declarative, modular NixOS flake managing two hosts (desktop + thinkpad) with Home-Manager, SOPS secrets, Niri Wayland compositor, Noctalia shell, and a comprehensive AI agent orchestration layer. 274 Nix files, 62 shell scripts, 6 JS hooks.

## Architecture

```
System/
├── flake.nix                    # Flake entry: inputs, makeSystem/makeHome factories, inventory-driven host loop
├── flake.lock                   # Pinned input hashes
├── justfile                     # Task runner: format, lint, modules, security, check, nixos, home, qa, sops-*
├── .sops.yaml                   # SOPS age key binding + path regex rules
├── secrets/secrets.yaml         # Age-encrypted secrets (SOPS)
├── shared/                      # Cross-boundary Nix helpers (NixOS ↔ Home-Manager)
│   ├── constants.nix            # SSOT: user identity, fonts, colors, keyboard, ports, proxies, paths
│   ├── option-helpers.nix       # Typed NixOS option constructors (mkBoolOption, mkStrOption, etc.)
│   ├── alias-helpers.nix        # Shared shell alias injection (zsh + bash)
│   └── secret-loader.nix        # Bash fn: load SOPS secrets from /run/secrets/
├── hosts/
│   ├── _inventory.nix           # Host list → flake.nix (single source of truth)
│   ├── desktop/                 # Desktop PC: gaming, full virt, Mullvad
│   └── thinkpad/                # Laptop: Bluetooth, TLP, NVIDIA dGPU, power mgmt
├── nixos/modules/               # System-level modules (two-level import pattern)
│   ├── default.nix              # Root loader → 10 category dirs
│   ├── core/                    # Bootloader, Nix, users, SOPS, timezone, i18n, env, stability, validation
│   ├── hardware/                # PipeWire audio, Bluetooth, NVIDIA GPU, libinput, upower, thermal
│   ├── desktop/                 # Niri compositor, SDDM, X11 disabled, XDG portals
│   ├── network/                 # NetworkManager, DNSCrypt, Mullvad VPN, Tailscale, Tor
│   ├── security-stack/          # Kernel/sysctl hardening, firewall, AIDE, AppArmor, Firejail, OpenSnitch
│   ├── apps/                    # Browser deps, Flatpak, Gaming (Steam/Proton/MangoHud), Syncthing
│   ├── virtualization/          # Docker, VirtualBox, libvirt, Waydroid, nix-ld
│   ├── observability/           # Netdata, Scrutiny (SMART), Glance dashboard, Loki log aggregation
│   ├── performance/             # Boot optimization
│   └── maintenance/             # Cleanup timers, Restic backup, nh helper
├── home/                        # Home-Manager user-space configuration
│   ├── home.nix                 # Entry point → core, programs, scripts, desktop, themes
│   ├── core/                    # User account, session vars, GTK/dconf, activation scripts, desktop entries
│   ├── packages/                # 14 package lists: cli, applications, development, multimedia, privacy, wayland, etc.
│   ├── programs/
│   │   ├── terminal/            # Zsh, Alacritty, Zellij, 20+ CLI tools (fzf, bat, eza, yazi, starship, etc.)
│   │   ├── ai-agents/           # Claude Code, Codex, Forge, OpenCode, Pi wrappers + config + services
│   │   ├── nvf/                 # Neovim via NVF framework
│   │   ├── zen-browser/         # Zen Browser multi-profile with per-profile Mullvad SOCKS5 proxies
│   │   ├── languages/           # Go, Python, JS/Node, LSP servers, mise version manager
│   │   ├── isolation/           # Wayland browser sandbox wrappers
│   │   └── *.nix                # brave, discord (nixcord), gpg, obs, spicetify, ssh, tailscale, thunar, etc.
│   ├── desktop/                 # Niri config (bindings/layout/rules/animations/idle/lock), Noctalia shell, MIME, Qt, udiskie
│   ├── themes/                  # Stylix engine, Catppuccin Mocha palette, theme options
│   └── scripts/                 # User-level scripts (nerdfont-fzf, build helpers)
├── scripts/
│   ├── ai/                      # Agent launcher, iter, log analyzer, dashboard, inventory, registry, skills-sync
│   │   └── android-re/          # Full Android RE toolkit: AVD mgmt, Frida hooks, mitmproxy, static analysis
│   ├── apps/                    # Desktop wrappers: browser-select, youtube-mpv, xdg-open, playwright-mcp
│   ├── build/                   # Quality gates: modules-check, packages-check, pre-commit/push hooks, shellcheck-nix-inline
│   ├── hardware/                # nvidia-fans control
│   ├── lib/                     # Shared shell libs: logging, test-helpers, fzf-theme, AWK utils, require
│   ├── sops/                    # SOPS editing helpers (tmpfs-backed)
│   └── system/report/           # Modular health report: core, observability, security collectors
└── docs/guides/                 # User guides: AI agents, Alacritty, Neovim, Niri, Yazi, Zellij
```

## Key Files

| File | Purpose |
|------|---------|
| `flake.nix` | Flake entry: 15 inputs, makeSystem/makeHome factories, inventory-driven host loop |
| `justfile` | All task automation (`just all`, `just qa`, `just nixos`, `just home`, `just sops-*`) |
| `shared/constants.nix` | SSOT for user identity, fonts, Catppuccin Mocha colors, keyboard layout, service ports, proxy endpoints |
| `shared/option-helpers.nix` | NixOS option type constructors used by system modules |
| `hosts/_inventory.nix` | Host registry — add/remove hosts here, flake.nix reads it automatically |
| `nixos/modules/default.nix` | Root loader importing 10 category directories |
| `nixos/modules/validation.nix` | Cross-module conflict assertions (audio, GPU, VPN, firewall, sandboxing, display manager) |
| `nixos/modules/security.nix` | Kernel hardening, sysctl, nftables firewall, AIDE, AppArmor, journald config |
| `home/programs/ai-agents/` | AI agent wrappers for Claude Code, Codex, Forge, OpenCode, Pi — config, helpers, services, activation |
| `home/programs/zen-browser/` | Multi-profile browser with per-profile Mullvad SOCKS5 proxy routing |
| `home/desktop/niri/` | Niri compositor config split: bindings, layout, rules, animations, idle, lock, input |
| `scripts/ai/_agent-registry.sh` | SSOT for all AI agent aliases, command mappings, and workflow suffixes |
| `scripts/build/modules-check.sh` | Validates every .nix file is imported by its parent default.nix |

## Module Map

### NixOS System Modules (opt-in via `mySystem.*`)

All NixOS modules use `options.mySystem.<module>` for per-host enablement. Import pattern: flat `.nix` files at `nixos/modules/` level, organized into category subdirs via their `default.nix`.

| Category | Modules | Scope |
|----------|---------|-------|
| `core/` | bootloader, nix daemon, users, sops, timezone, i18n, environment, stability (earlyoom/BBR/inotify), validation | Always active |
| `hardware/` | PipeWire audio, Bluetooth (opt-in), NVIDIA proprietary + VA-API, libinput, upower, thermald | Always active except Bluetooth |
| `desktop/` | Niri scrollable-tiling, SDDM Wayland, X11 disabled, XDG portals | Always active |
| `network/` | NetworkManager + resolved, DNSCrypt (opt-in), Mullvad VPN lockdown (opt-in), Tailscale, Tor (opt-in) | Mixed |
| `security-stack/` | Kernel/sysctl hardening, nftables firewall, AIDE, AppArmor, Firejail (opt-in), OpenSnitch (opt-in), MAC randomization (opt-in) | Mixed |
| `apps/` | Browser deps (Widevine), Flatpak (opt-in), Gaming/Steam/Proton (opt-in), Syncthing (opt-in) | Mixed |
| `virtualization/` | Docker/VBox/libvirt (opt-in), nix-ld (always) | Mixed |
| `observability/` | Netdata (opt-in), Scrutiny SMART (opt-in), Glance dashboard (opt-in), Loki log aggregation | All opt-in |
| `performance/` | Boot optimization | Always active |
| `maintenance/` | Cleanup timers (opt-in), Restic backup (opt-in), nh helper | Mixed |

### Home-Manager Modules

| Category | Contents |
|----------|----------|
| `core/` | User account, session vars, GTK/dconf, activation, desktop entries |
| `packages/` | 14 package category files (cli, applications, development, multimedia, privacy, wayland, etc.) |
| `programs/terminal/` | Zsh (aliases/functions/config), Alacritty, Zellij, 20+ CLI tools (fzf, bat, eza, yazi, starship, etc.) |
| `programs/ai-agents/` | Multi-provider AI agent orchestration: config, helpers, services, activation, log analysis |
| `programs/nvf/` | Neovim via NVF framework |
| `programs/zen-browser/` | Multi-profile Zen Browser with per-profile Mullvad SOCKS5 proxy |
| `programs/languages/` | Go, Python, JS/Node, LSP servers, mise version manager |
| `programs/isolation/` | Wayland browser sandbox wrappers |
| `desktop/` | Niri (7 sub-modules), Noctalia shell/bar/plugins, MIME, Qt, udiskie |
| `themes/` | Stylix engine, Catppuccin Mocha palette, theme options |

### Host-Specific Overrides

- **desktop**: Gaming (Gamescope), full virtualization, Mullvad VPN
- **thinkpad**: Bluetooth, TLP power management, NVIDIA dGPU power switching, thermal control

## Data Flow

### Build Pipeline

```
hosts/_inventory.nix → flake.nix (makeSystem/makeHome factories)
  → nixosConfigurations.<hostname> (nixpkgs.lib.nixosSystem)
    → hosts/<hostname>/configuration.nix
      → ../../nixos/modules (all system modules via default.nix chain)
      → ./modules (host-specific overrides)
  → homeConfigurations.<user>@<hostname> (home-manager.lib.homeManagerConfiguration)
    → home/home.nix
      → core, programs, scripts, desktop, themes
```

### Secrets Flow

```
secrets/secrets.yaml (age-encrypted)
  → sops-nix decrypts at activation time
  → /run/secrets/<key> (tmpfs, never on disk)
  → consumed by: systemd services, shell scripts via _load_secret(), Nix config via sops.placeholder.*
```

### Constants Propagation

```
shared/constants.nix
  → imported directly by flake.nix
  → passed via specialArgs.constants to all NixOS modules and Home-Manager modules
  → used for: terminal, editor, fonts, colors, keyboard, ports, proxy endpoints, paths
```

### AI Agent Orchestration Flow

```
scripts/ai/_agent-registry.sh (alias → command mapping)
  → agent-launcher.sh (interactive fzf) or agent-iter.sh (headless)
  → agent-log-wrapper.sh (stdout/stderr split + timestamps)
  → agent-analyze.sh / agent-dashboard.sh (log analysis)
  → home/programs/ai-agents/ (Nix wrappers provide env vars, profiles, config files)
```

## Dependencies

### External Flake Inputs

| Input | Version | Notes |
|-------|---------|-------|
| `nixpkgs` | unstable | Primary package set |
| `nixpkgs-stable` | 25.11 | Select stable packages via `pkgsStable` |
| `home-manager` | master | User environment management |
| `sops-nix` | latest | Age-encrypted secret management |
| `stylix` | latest | System-wide theming (Catppuccin Mocha) |
| `niri` | latest | ⚠️ Does NOT follow nixpkgs — pinned mesa for compatibility |
| `noctalia` | latest | Shell/bar/launcher for Niri |
| `spicetify-nix` | latest | Spotify customization |
| `nixcord` | latest | Discord theming |
| `nvf` | latest | Neovim configuration framework |
| `nix-wallpaper` | latest | Nix-themed wallpaper generator |
| `ghgrab` | latest | GitHub release downloader |
| `zellij-tui` | latest | Zellij TUI extension |
| `zen-browser` | latest | Zen Browser flake (beta channel) |
| `forgecode` | latest | Forge AI coding agent |

### Internal Dependency Graph

```
flake.nix
  ├── shared/constants.nix (used everywhere via specialArgs)
  ├── shared/option-helpers.nix (used by nixos/modules/*.nix for option definitions)
  ├── shared/secret-loader.nix (used by terminal/zsh + ai-agents)
  ├── shared/alias-helpers.nix (used by terminal/zsh)
  │
  ├── hosts/_inventory.nix → hosts/<name>/configuration.nix
  │     ├── ../../nixos/modules → 10 categories → ~50 flat module files
  │     └── ./modules → host-specific hardware/power overrides
  │
  └── home/home.nix → core, programs (16 subdirs), desktop, themes
        └── programs/ai-agents → references scripts/ai/*, shared/secret-loader.nix
```

### Script Dependency Graph

```
scripts/lib/logging.sh ← sourced by almost all scripts
scripts/lib/test-helpers.sh ← sourced by all *-test.sh files
scripts/lib/fzf-theme.sh ← sourced by agent-launcher, agent-inventory, agent-dashboard
scripts/lib/error-patterns.sh ← sourced by agent-analyze, report-collectors-core
scripts/lib/require.sh ← sourced by android-re helpers
scripts/lib/awk-utils.awk + extract-nix-shell.awk ← composed by shellcheck-nix-inline.sh
scripts/ai/_agent-registry.sh ← sourced by agent-launcher.sh, agent-iter.sh
```

## Conventions

- **Nix formatting**: `nixfmt --strict` (run via `just format`)
- **Nix linting**: `statix check` (run via `just lint`)
- **Shell linting**: `shellcheck` on all `.sh` files + inline Nix shell snippets
- **Commits**: GPG-signed (enforced by pre-push hook), semantic prefixes (`feat:`, `fix:`, `refactor:`, `chore:`)
- **Module pattern**: Flat `.nix` files at `nixos/modules/` level, organized into category subdirs via `default.nix`
- **Options**: All NixOS modules expose `mySystem.<module>.enable` for per-host opt-in
- **Constants**: `shared/constants.nix` is the SSOT — never hardcode values that belong there
- **Scripts**: `#!/usr/bin/env bash` + `set -euo pipefail`; sourced libraries (lib/) omit `set -euo pipefail`
- **Tests**: `*-test.sh` suffix alongside the script under test; run with `bash <script>-test.sh`
- **Secrets**: Never in plaintext on disk; always via SOPS → `/run/secrets/` → `_load_secret()` or `sops.placeholder.*`
- **Host config**: Add host to `hosts/_inventory.nix`, create `hosts/<name>/` directory, done
- **Git hooks**: `ln -sf ../../scripts/build/pre-commit-hook.sh .git/hooks/pre-commit` and `pre-push-hook.sh`

## Build & Test

```bash
just                    # List all tasks
just format             # Format .nix with nixfmt
just lint               # statix + shellcheck
just modules            # Verify all .nix files are imported by parent default.nix
just security           # Scan for risky patterns and plaintext secret leaks
just check              # nix flake check (eval all outputs)
just eval-audit         # Measure eval time for all host outputs
just eval-current       # Measure eval time for current host only
just qa                 # Full QA: modules + security + check + eval-audit
just qa-fast            # Fast QA: modules + security + eval-current (parallel)
just nixos              # nh os switch (current host)
just nixos desktop      # nh os switch --hostname desktop
just nixos-fast         # Skip validation, no NOM
just home               # nh home switch
just all                # Full pipeline: modules + lint + format + security + check + nixos + home
just hardening          # systemd-analyze security report
just perf               # Boot/session performance diagnostics
```

**Shell tests**: `bash scripts/build/modules-check-test.sh`, `bash scripts/ai/agent-launcher-test.sh`, etc.

## Gotchas

1. **Niri flake input does NOT follow nixpkgs** — pinned mesa version required. Changing this breaks GPU rendering. See `flake.nix` comment on niri input.
2. **Python test overrides in flake.nix** — `picosvg`, `nanoemoji`, `gftools` have `doCheck = false` due to sandbox-incompatible font tests. Track upstream fixes.
3. **Two-level import pattern** — flat `.nix` files at `nixos/modules/` level must be imported from the correct category `default.nix`. Running `just modules` catches missing imports.
4. **Cross-module assertions** — `nixos/modules/validation.nix` enforces mutual exclusion (TLP vs power-profiles-daemon, PulseAudio vs PipeWire, Mullvad vs DNSCrypt, etc.).
5. **High-churn files** (from git history): `flake.nix` (26 commits), `home/programs/default.nix` (21), `home/packages/applications.nix` (18), `nixos/modules/graphics.nix` (15), `nixos/modules/default.nix` (16).
6. **Android RE spoof sync** — `_spoof-table.sh` and `frida-spoof-build.js` define Pixel 7 spoof independently; must be kept in sync.
7. **Agent registry** — `_agent-registry.sh` is sourced by both launcher and iter; must be sourced AFTER `logging.sh`.
8. **Pre-commit hook** hardcodes deadnix exclude for `zellij/layouts.nix`.
9. **Secret decryption** — `just sops-edit` writes decrypted file to `$XDG_RUNTIME_DIR` (tmpfs). If interrupted, OS reclaims automatically.
10. **Desktop vs thinkpad differences** — thinkpad has no gaming/virtualization/Mullvad; desktop has no Bluetooth/TLP/NVIDIA-dGPU-specific modules.

## Security Considerations

- **SOPS + age encryption** for all secrets at rest; plaintext only in `/run/secrets/` (tmpfs)
- **Kernel hardening**: sysctl params, ALSR, restrict dmesg, disable uncommon protocols
- **Firewall**: nftables-based, enabled by default (asserted in validation.nix)
- **AppArmor**: mandatory access control (asserted as always-on)
- **Firejail sandboxing**: wrapped binaries for high-risk apps (opt-in per host)
- **OpenSnitch**: per-app network firewall with eBPF monitoring (opt-in)
- **MAC randomization**: on boot via macchanger (opt-in)
- **Mullvad VPN**: lockdown mode + quantum-resistant key exchange (desktop only)
- **Tor**: client + torsocks (opt-in per host)
- **GPG-signed commits**: enforced by pre-push hook
- **Gitignore**: blocks `.key`, `.pem`, `.p12`, `.env`, `id_rsa`, `id_ed25519`, `*-decrypted.*`
- **Proxy isolation**: each browser profile gets a dedicated Mullvad SOCKS5 exit — never mixed
- **DNS**: DNSCrypt available (opt-in), conflicts with Mullvad DNS (asserted)
