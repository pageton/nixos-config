# Glance Dashboard Widgets

Configuration fragments for the Glance self-hosted dashboard (localhost:8082).

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Glance module definition — imports settings, GitHub token service |
| `_settings.nix` | Full dashboard layout (4 pages: Home, Search, YouTube, GitHub) with all widget data consolidated |
| `_service-sites.nix` | Service health check URLs (derived from `constants.urls`) |
| `_color-helpers.nix` | Hex-to-Glance-HSL color conversion utility |
| `_github-token-service.nix` | Systemd service to bootstrap GitHub token from `gh auth` |

## Conventions

- Widget data consolidated into `_settings.nix` for locality
- Files prefixed with `_` are data/logic-only (not NixOS modules)
- Colors derived from `constants.color.*` via `hexToGlanceHsl` (Catppuccin Mocha)
- Dashboard binds to `constants.localhost:constants.ports.glance` (no external access)
- GitHub API widgets require `gh auth` setup — token injected via `environmentFile`

## Dependencies

- **Imported by**: `nixos/modules/observability/default.nix` → `../glance`
- **Opt-in**: `mySystem.glance.enable = true` in host config
- **Requires**: `constants` (specialArgs), `user` (specialArgs)
