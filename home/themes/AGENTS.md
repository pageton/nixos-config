# Themes

System-wide theming via Stylix engine with Catppuccin Mocha palette. Controls fonts, cursor, icons, wallpaper, and application target themes.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Imports options and stylix modules |
| `options.nix` | Theme submodule options: rounding, gaps, opacity, bar settings |
| `palette.nix` | Catppuccin Mocha color palette attrset (plain Nix, not a module) |
| `stylix.nix` | Stylix config: fonts, cursor, icons, wallpaper, per-app targets |

## Conventions

- `palette.nix` is a plain attrset imported directly by `stylix.nix` — not a NixOS/HM module
- Color values use hex strings matching Catppuccin Mocha spec
- Theme options (rounding, gaps, opacity) are consumed by Niri, Noctalia, and terminal configs
- Wallpaper is managed via Stylix (`config.stylix.image`)

## Dependencies

- **Inputs**: Stylix flake input, `nix-wallpaper` flake input
- **Imported by**: `home/home.nix`
- **Consumed by**: niri, noctalia, alacritty, and all Stylix-enabled targets
