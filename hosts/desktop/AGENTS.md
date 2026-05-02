# Desktop Host Configuration

Gaming/workstation PC host. Enables full virtualization stack, gaming with Gamescope, Mullvad VPN lockdown, Tor, and system monitoring.

## Files

| File | Purpose |
|------|---------|
| `configuration.nix` | Host entry point: imports hardware-config, local-packages, nixos/modules, and ./modules. Sets all `mySystem.*` opts explicitly. |
| `hardware-configuration.nix` | Auto-generated hardware scan (filesystems, kernel modules, initrd). **Do not edit manually.** |
| `local-packages.nix` | Host-specific system packages (`showmethekey`, `fontconfig`). Receives `pkgs` and `pkgsStable`. |
| `modules/default.nix` | Imports all host-specific modules (currently `power.nix`). |
| `modules/power.nix` | Desktop power management — enables `gamemode` for CPU governor auto-switching during gaming. |

## Enabled Modules

| Module | Key options |
|--------|-------------|
| `virtualisation` | `enable = true` (Docker, VirtualBox, libvirt) |
| `gaming` | `enable = true`, `enableGamescope = true` |
| `mullvadVpn` | `enable = true` |
| `tor` | `enable = true` |
| `netdata` | `enable = true` |
| `scrutiny` | `enable = true` |
| `syncthing` | `enable = true` |
| `glance` | `enable = true` |
| `macchanger` | `enable = true` |
| `flatpak` | `enable = true` |
| `sandboxing` | `enable = true`, user namespaces + wrapped binaries |
| `bluetooth` | Explicitly disabled (`enable = false`) |

## Conventions

- All `mySystem.*` options are set explicitly, even disabled ones — this is intentional for auditability.
- `local-packages.nix` receives both `pkgs` and `pkgsStable` args; use `pkgsStable` for packages that break on unstable.
- Host-specific overrides live in `modules/`; shared system modules live in `../../nixos/modules`.

## Dependencies

- **Imports**: `../../nixos/modules` (shared system modules), `./modules` (host-specific overrides)
- **Imported by**: `flake.nix` via `makeSystem` factory (driven by `hosts/_inventory.nix`)
