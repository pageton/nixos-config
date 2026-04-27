# Desktop Environment

Compositor, shell, theming, and system integration for the Wayland desktop. Niri compositor + Noctalia shell + Qt/MIME/udiskie configuration.

## Architecture

```
home/desktop/
├── default.nix    # Imports all sub-modules
├── niri/          # Niri compositor config (has AGENTS.md)
├── noctalia/      # Noctalia shell: bar, launcher, control center, notifications
├── mime/          # Default application associations (MIME types)
├── qt/            # Qt Wayland integration and theme settings
└── udiskie/       # Auto-mount removable media with notifications
```

## Key Files

| File | Purpose |
|------|---------|
| `default.nix` | Imports: niri, noctalia, qt, mime, udiskie |
| `noctalia/default.nix` | Noctalia shell config: colors, settings, control center, notifications |
| `noctalia/bar.nix` | Status bar configuration |
| `noctalia/plugins.nix` | Shell plugins |
| `noctalia/packages.nix` | Noctalia package overrides |

## Conventions

- Noctalia replaces waybar, swaync, fuzzel, swaylock, and power menu
- Stylix integration: colors derived from `config.lib.stylix.colors`
- Niri subdirectory has its own AGENTS.md with detailed module breakdown

## Dependencies

- **Inputs**: Stylix (colors/fonts), noctalia flake input, niri flake input
- **Imported by**: `home/home.nix`
