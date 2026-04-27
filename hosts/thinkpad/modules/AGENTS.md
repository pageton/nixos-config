# Thinkpad Host Modules

Host-specific NixOS modules for the ThinkPad laptop: boot configuration, NVIDIA dGPU power management, TLP power saving, and thermal control.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Imports all thinkpad-specific modules |
| `boot.nix` | Thinkpad-specific boot/kernel parameters |
| `nvidia.nix` | NVIDIA dGPU power switching and offload config |
| `power.nix` | Power management settings for laptop |
| `tlp.nix` | TLP daemon for battery and power optimization |
| `thermal.nix` | Thermal management and fan control |

## Gotchas

1. **TLP vs power-profiles-daemon** — `validation.nix` enforces mutual exclusion; TLP replaces power-profiles-daemon on thinkpad
2. **NVIDIA dGPU** — power switching must be configured carefully to avoid battery drain
3. **Desktop counterpart** — desktop has only `modules/power.nix` (minimal power config)

## Dependencies

- **Imported by**: `hosts/thinkpad/configuration.nix` → `./modules`
