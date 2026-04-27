# Glance Dashboard Widgets

Configuration fragments for the Glance self-hosted dashboard (localhost:8082). Each file is a plain Nix attrset imported by `glance/default.nix`.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Glance module definition with full dashboard layout (3 pages: Home, Search, YouTube) |
| `_bookmarks.nix` | Bookmark groups for the bookmarks widget |
| `_markets.nix` | Stock/crypto market tickers |
| `_rss-sections.nix` | RSS feed sections (releases, news) |
| `_search-bangs.nix` | DuckDuckGo bang shortcuts |
| `_service-sites.nix` | Service health check URLs for the monitor widget |
| `_youtube-channels.nix` | YouTube channel subscriptions for the videos widget |

## Conventions

- Widget config files prefixed with `_` are data-only attrsets (not modules)
- `default.nix` assembles all widget configs into the full Glance settings
- Dashboard binds to `127.0.0.1:8082` (no external access)
- Branding uses Catppuccin Mocha colors

## Dependencies

- **Imported by**: `nixos/modules/observability/default.nix` → `../glance`
- **Opt-in**: `mySystem.glance.enable = true` in host config
