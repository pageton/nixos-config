# NixOS System Modules

System-level NixOS modules using a two-level import pattern: flat `.nix` files at this level, organized into category subdirectories via `default.nix`. All modules expose `mySystem.<module>.enable` for per-host opt-in.

## Architecture

```
nixos/modules/
├── default.nix              # Root loader → 10 category directories
├── core/                    # Boot, Nix daemon, users, SOPS, locale, stability
├── hardware/                # Audio, Bluetooth, GPU, input, power, thermal
├── desktop/                 # Niri compositor, SDDM, X11 disabled, XDG portals
├── network/                 # NetworkManager, DNSCrypt, Mullvad, Tailscale, Tor
├── security-stack/          # Kernel hardening, firewall, Firejail, OpenSnitch, MAC
├── apps/                    # Browser deps, Flatpak, Gaming, Syncthing
├── virtualization/          # Docker, VirtualBox, libvirt, nix-ld
├── observability/           # Netdata, Scrutiny, Glance, Loki
├── performance/             # Boot optimization
├── maintenance/             # Cleanup timers, Restic backup, nh
├── glance/                  # Glance dashboard widget configs (RSS, bookmarks, etc.)
├── helpers/                 # Shared module helper expressions
└── *.nix                    # ~50 flat module files
```

## Module Map

| Category | Modules | Scope |
|----------|---------|-------|
| `core/` | bootloader, nix, users, sops, timezone, i18n, environment, stability, validation | Always active |
| `hardware/` | audio (PipeWire), android (ADB), bluetooth, graphics (NVIDIA), libinput, upower, thermal | Always active except bluetooth |
| `desktop/` | niri, sddm, xserver (disabled), xdg-desktop-portal | Always active |
| `network/` | networking (NM+resolved), dnscrypt-proxy, mullvad, tailscale, tor | Mixed opt-in |
| `security-stack/` | security (kernel/sysctl/nftables/AIDE/AppArmor), opsec, sandboxing (Firejail), opensnitch, macchanger | Mixed opt-in |
| `apps/` | browser-deps, flatpak, gaming (Steam/Proton/MangoHud), syncthing | Mixed opt-in |
| `virtualization/` | virtualisation (Docker/VBox/libvirt), nix-ld | Mixed opt-in |
| `observability/` | monitoring, netdata, scrutiny, glance, loki | All opt-in |
| `performance/` | boot-optimization | Always active |
| `maintenance/` | cleanup, backup (Restic), nh | Mixed opt-in |

## Key Files

| File | Purpose |
|------|---------|
| `default.nix` | Root loader importing 10 category directories |
| `validation.nix` | Cross-module conflict assertions (audio, GPU, VPN, firewall, sandboxing, display manager) |
| `security.nix` | Kernel hardening, sysctl, nftables firewall, AIDE, AppArmor, journald config |
| `graphics.nix` | NVIDIA proprietary driver, VA-API, Wayland env vars |
| `cleanup.nix` | Scheduled cleanup timers for downloads, caches, Docker |
| `sandboxing.nix` | Firejail wrapped binaries with per-app profiles |
| `glance/default.nix` | Glance dashboard (localhost:8082) with widgets |

## Conventions

- **Two-level import pattern**: flat `.nix` files live here; category `default.nix` files import them via relative paths (e.g., `../bootloader.nix`)
- **Options**: all modules use `mySystem.<module>.enable` for per-host opt-in
- **Validation**: `validation.nix` enforces mutual exclusion (TLP vs power-profiles-daemon, PulseAudio vs PipeWire, Mullvad vs DNSCrypt, etc.)
- **Adding a module**: create `.nix` file → import from the correct category `default.nix` → enable in host config

## Gotchas

1. **Niri mesa pin** — niri flake input does NOT follow nixpkgs; changing this breaks GPU rendering
2. **Two-level imports** — flat files must be imported from the correct category `default.nix`; run `just modules` to verify
3. **Cross-module assertions** — `validation.nix` will fail the build if conflicting modules are enabled simultaneously
4. **security-stack contains opsec.nix** — it's a subdirectory file (`security-stack/opsec.nix`), not a flat file at this level

## Dependencies

- **Imports from**: `shared/constants.nix` (via specialArgs), `shared/option-helpers.nix`
- **Imported by**: `hosts/<hostname>/configuration.nix` imports `../../nixos/modules`
