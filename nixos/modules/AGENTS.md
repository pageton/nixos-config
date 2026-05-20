# NixOS System Modules

System-level NixOS modules using a two-level import pattern: flat `.nix` files at this level, organized into category subdirectories via `default.nix`. All modules expose `mySystem.<module>.enable` for per-host opt-in.

## Directory Structure

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
├── helpers/                 # Shared module helper expressions (systemd factories, hardening wrappers)
├── bootloader.nix
├── nix.nix
├── users.nix
├── sops.nix
├── timezone.nix
├── i18n.nix
├── environment.nix
├── stability.nix
├── validation.nix
├── audio.nix
├── android.nix
├── bluetooth.nix
├── graphics.nix
├── libinput.nix
├── upower.nix
├── thermal.nix
├── niri.nix
├── sddm.nix
├── xserver.nix
├── xdg-desktop-portal.nix
├── networking.nix
├── dnscrypt-proxy.nix
├── mullvad.nix
├── tailscale.nix
├── tor.nix
├── security.nix
├── firewall.nix
├── aide.nix
├── apparmor.nix
├── opensnitch.nix
├── macchanger.nix
├── opsec.nix
├── sandboxing.nix
├── web-re.nix
├── browser-deps.nix
├── flatpak.nix
├── gaming.nix
├── syncthing.nix
├── virtualization.nix
├── docker.nix
├── virtualbox.nix
├── libvirt.nix
├── nix-ld.nix
├── netdata.nix
├── scrutiny.nix
├── glance.nix
├── loki.nix
├── monitoring.nix
├── boot-optimization.nix
├── cleanup.nix
├── backup.nix
├── nh.nix
├── android.nix
├── fwupd.nix
├── printing.nix
├── secure-boot.nix
├── vnc.nix
├── yggdrasil.nix
└── i2pd.nix
```
## Module Map

| Category | Modules | Scope |
|----------|---------|-------|
| `core/` | bootloader, nix, users, sops, timezone, i18n, environment, stability, validation | Always active |
| `hardware/` | audio (PipeWire), android (ADB), bluetooth, graphics (NVIDIA), libinput, upower, thermal | Always active except bluetooth |
| `desktop/` | niri, sddm, xserver (disabled), xdg-desktop-portal | Always active |
| `network/` | networking (NM+resolved), dnscrypt-proxy, mullvad, tailscale, tor | Mixed opt-in |
| `security-stack/` | security (kernel/sysctl/nftables/AIDE/AppArmor), opsec (session lock, zram, NTS chrony), sandboxing (Firejail), opensnitch, macchanger, web-re (opt-in) | Mixed opt-in |
| `apps/` | browser-deps, flatpak, gaming (Steam/Proton/MangoHud), syncthing | Mixed opt-in |
| `virtualization/` | virtualisation (Docker/VBox/libvirt), nix-ld | Mixed opt-in |
| `observability/` | monitoring (base tools), netdata, scrutiny, glance, loki | All opt-in |
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
| `android.nix` | Android ADB, fastboot, SDK emulator support |
| `web-re.nix` | Web RE and security assessment tools (opt-in) |
| `monitoring.nix` | Base hardware sensor monitoring and resource tools |
| `helpers/_systemd-helpers.nix` | Systemd hardening, persistent timers, oneshot service factories |

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
5. **Orphaned modules** — `fwupd.nix`, `printing.nix`, `secure-boot.nix`, `vnc.nix`, `yggdrasil.nix`, `i2pd.nix` exist here but are not imported by any category `default.nix`. They will not be included in any build until wired up.

## Dependencies

- **Imports from**: `shared/constants.nix` (via specialArgs), `shared/option-helpers.nix`
- **Imported by**: `hosts/<hostname>/configuration.nix` imports `../../nixos/modules`
