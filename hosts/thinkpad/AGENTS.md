# ThinkPad Host Configuration

Laptop host. Enables Bluetooth, TLP power management, NVIDIA dGPU power switching, and thermal control. Disables gaming, virtualization, and Mullvad VPN (desktop-only features).

## Files

| File | Purpose |
|------|---------|
| `configuration.nix` | Host entry point: imports hardware-config, local-packages, nixos/modules, and ./modules. Sets all `mySystem.*` opts explicitly (even disabled). |
| `hardware-configuration.nix` | Auto-generated hardware scan (filesystems, kernel modules, initrd). **Do not edit manually.** |
| `local-packages.nix` | Host-specific system packages (`tlp`, `smartmontools`, `powertop`). Receives `pkgs` and `pkgsStable`. |
| `modules/default.nix` | Imports all host-specific modules (boot, nvidia, power, thermal, tlp). |
| `modules/boot.nix` | Bootloader configuration for ThinkPad. |
| `modules/nvidia.nix` | NVIDIA dGPU power management (dynamic offloading). |
| `modules/power.nix` | Power management settings. |
| `modules/thermal.nix` | Thermal daemon configuration. |
| `modules/tlp.nix` | TLP power management (battery optimization, charge thresholds). |

## Enabled Modules

| Module | Key options |
|--------|-------------|
| `bluetooth` | `enable = true` |
| `codex` | `enable = true` |
| `flatpak` | `enable = true` |
| `glance` | `enable = true` |
| `macchanger` | `enable = true` |
| `netdata` | `enable = true` |
| `sandboxing` | `enable = true`, user namespaces + wrapped binaries |
| `scrutiny` | `enable = true` |
| `syncthing` | `enable = true` |
| `tailscale` | `enable = true` |
| `tor` | `enable = true` |
| `amdRyzenThermal` | Explicitly disabled (`enable = false`) — Intel CPU |
| `cloudflared` | Explicitly disabled (`enable = false`) |
| `dnscryptProxy` | Explicitly disabled (`enable = false`) |
| `gaming` | Explicitly disabled (`enable = false`) |
| `mullvadVpn` | Explicitly disabled (`enable = false`) |
| `vaultwarden` | Explicitly disabled (`enable = false`) |
| `virtualisation` | Explicitly disabled (`enable = false`) |
| `webRe` | Explicitly disabled (`enable = false`) |

## Conventions

- All `mySystem.*` options are set explicitly, even disabled ones — this is intentional for auditability.
- `local-packages.nix` receives both `pkgs` and `pkgsStable` args; use `pkgsStable` for packages that break on unstable.
- Host-specific overrides live in `modules/`; shared system modules live in `../../nixos/modules`.

## Dependencies

- **Imports**: `../../nixos/modules` (shared system modules), `./modules` (host-specific overrides)
- **Imported by**: `flake.nix` via `makeSystem` factory (driven by `hosts/_inventory.nix`)
