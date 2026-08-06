# Themes

System-wide theming via Stylix engine with Catppuccin Mocha palette. Controls fonts, cursor, icons, wallpaper, and application target themes.

## Files

| File                        | Purpose                                                          |
| --------------------------- | ---------------------------------------------------------------- |
| `default.nix`               | Imports options and stylix modules                               |
| `options.nix`               | Theme submodule options: rounding, gaps, opacity, bar settings   |
| `palette.nix`               | Catppuccin Mocha color palette attrset (plain Nix, not a module) |
| `stylix.nix`                | Stylix config: fonts, cursor, icons, wallpaper, per-app targets  |
| `librewolf-userChrome.css`  | Custom CSS overrides for LibreWolf browser chrome (UI)           |
| `librewolf-userContent.css` | Custom CSS overrides for LibreWolf content (web pages)           |

## Directory Structure

```
home/themes/
├── default.nix                # Import hub (options + stylix modules)
├── options.nix                # Theme submodule options (rounding, gaps, opacity)
├── palette.nix                # Catppuccin Mocha color palette attrset
├── stylix.nix                 # Stylix config: fonts, cursor, icons, wallpaper, targets
├── librewolf-userChrome.css   # Custom CSS for LibreWolf browser chrome (UI)
└── librewolf-userContent.css  # Custom CSS for LibreWolf content (web pages)

## Conventions

- `palette.nix` is a plain attrset imported directly by `stylix.nix` — not a NixOS/HM module
- Color values use hex strings matching Catppuccin Mocha spec
- Theme options (rounding, gaps, opacity) are consumed by Niri and terminal configs
- Wallpaper is managed via Stylix (`config.stylix.image`); Noctalia v5 reads its wallpaper from `programs.noctalia.settings.wallpaper` (see `home/desktop/noctalia/settings.nix`), reusing the same `nix-wallpaper` derivation

## Dependencies

- **Inputs**: Stylix flake input, `nix-wallpaper` flake input
- **Imported by**: `home/home.nix`
- **Consumed by**: niri, noctalia (via `programs.noctalia.settings`), alacritty, and all Stylix-enabled targets
```
