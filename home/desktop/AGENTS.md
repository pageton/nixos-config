# Desktop Environment

Compositor, shell, theming, and system integration for the Wayland desktop. Niri compositor + Noctalia v5 shell (active) + Qt/MIME/udiskie configuration.

## Architecture

```
home/desktop/
├── default.nix     # Imports all sub-modules
├── niri/           # Niri compositor config (has AGENTS.md)
├── noctalia/       # ACTIVE shell: Noctalia v5 (C++ native, TOML config)
├── mime/           # Default application associations (MIME types)
├── qt/             # Qt Wayland integration and theme settings
└── udiskie/        # Auto-mount removable media with notifications
```

## Key Files

| File                    | Purpose                                                       |
| ----------------------- | ------------------------------------------------------------- |
| `default.nix`           | Imports: niri, **noctalia**, qt, mime, udiskie                |
| `noctalia/default.nix`  | Loader: imports packages + settings                           |
| `noctalia/packages.nix` | `programs.noctalia.enable` + runtime deps (wl-clipboard)      |
| `noctalia/settings.nix` | `programs.noctalia.settings` — theme + wallpaper + bar (TOML) |

## Noctalia v5 notes

- **Binary**: `noctalia` (was `noctalia-shell` in v4). **IPC**: `noctalia msg <command>` (kebab-case single string; was `noctalia-shell ipc call <ns> <method>`).
- **Config**: TOML in `~/.config/noctalia/*.toml` (base layer) merged with GUI state at `~/.local/state/noctalia/settings.toml` (wins on conflict). Existing `config_version 12` state is preserved across switches.
- **No Stylix target** (v4 had `noctalia-shell.enable`). Catppuccin Mocha + wallpaper are hand-mirrored via `programs.noctalia.settings` in `noctalia/settings.nix`, reusing the same `nix-wallpaper` derivation as `themes/stylix.nix`.
- **Plugins**: v5 uses Luau (not v4's QML). The v4 clipboard/usb/port/screen QML plugins do NOT carry over; v5's built-in clipboard panel (`panel-toggle clipboard`) covers the core use case. Deferred: rebuild custom features as Luau plugins.

## Conventions

- **Noctalia v5 is the active shell** — bar, launcher, control center, notifications, power menu, theme engine
- Niri keybinds for shell control use Noctalia v5 IPC verbs (see `niri/bindings.nix`)
- Idle handled by swayidle (`niri/idle.nix`); lock via `noctalia msg session lock`
- `swaylock` config remains in `niri/lock.nix` as a fallback; primary lock is Noctalia's lockscreen

## Dependencies

- **Inputs**: `noctalia` (main branch, `homeModules.default`), `noctalia-greeter` (NixOS module, see `nixos/modules/greetd.nix`), Stylix (colors/fonts/wallpaper derivation), niri flake input
- **Imported by**: `home/home.nix`
