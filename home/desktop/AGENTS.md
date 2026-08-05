# Desktop Environment

Compositor, shell, theming, and system integration for the Wayland desktop. Niri compositor + DMS (DankMaterialShell) + Qt/MIME/udiskie configuration.

## Architecture

```
home/desktop/
├── default.nix     # Imports all sub-modules
├── niri/           # Niri compositor config (has AGENTS.md)
├── dms/            # DMS shell: bar, launcher, control center, notifications (has AGENTS.md)
├── mime/           # Default application associations (MIME types)
├── qt/             # Qt Wayland integration and theme settings
└── udiskie/        # Auto-mount removable media with notifications
```

## Key Files

| File               | Purpose                                            |
| ------------------ | -------------------------------------------------- |
| `default.nix`      | Imports: niri, dms, qt, mime, udiskie              |
| `dms/default.nix`  | `programs.dank-material-shell` enable + settings   |
| `dms/packages.nix` | Runtime deps not bundled by dms-shell (OCR/scan/…) |

## Conventions

- DMS replaces waybar, swaync, fuzzel, swaylock, and power menu
- DMS handles its own theming via matugen wallpaper palettes (no stylix target)
- Niri subdirectory has its own AGENTS.md with detailed module breakdown

## Dependencies

- **Inputs**: Stylix (colors/fonts), dank-material-shell flake input, niri flake input
- **Imported by**: `home/home.nix`
