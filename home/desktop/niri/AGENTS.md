# Niri Compositor Configuration

Niri scrollable-tiling Wayland compositor — Home Manager configuration split into focused sub-modules for keybinds, layout, window rules, animations, idle behavior, screen locking, and input handling.

## Files

| File              | Purpose                                                                                |
| ----------------- | -------------------------------------------------------------------------------------- |
| `default.nix`     | Main config: environment vars, spawn-at-startup, cursor, debug, layer-rules, lid-close |
| `bindings.nix`    | Keyboard shortcuts and keybind actions (Noctalia v5 IPC verbs for shell control)       |
| `layout.nix`      | Window layout rules, column widths, gaps, struts                                       |
| `rules.nix`       | Per-window/open rules (floating, fullscreen, workspace assignment)                     |
| `animations.nix`  | Transition and motion animations                                                       |
| `idle.nix`        | swayidle timeouts: dim (3m) → lock (8m) → DPMS off (20m)                               |
| `lock.nix`        | swaylock screen lock config (fallback; primary lock is Noctalia's lockscreen)          |
| `input.nix`       | Keyboard, mouse, touchpad, trackpoint settings                                         |
| `_auth-float.nix` | Auth dialog floating window rule (private/internal)                                    |

## Conventions

- Each concern is a separate `.nix` file imported by `default.nix`
- Files prefixed with `_` are internal/private helpers
- Host-specific behavior uses `isThinkpad` conditional (cursor size differences)
- `spawn-at-startup` launches: niri-auth-float, **noctalia** (v5 binary), cliphist (text + image watchers), wl-clip-persist

## Gotchas

1. **Niri flake does NOT follow nixpkgs** — pinned mesa for GPU compatibility; do not change this
2. **Noctalia v5 IPC** uses `noctalia msg <command>` (kebab-case single string). Key verbs: `panel-toggle launcher\|control-center\|session\|clipboard`, `session lock`, `volume-up\|volume-mute\|mic-mute`, `brightness-up\|brightness-down`, `media play-pause\|next\|previous`, `theme-mode-toggle`, `settings-toggle`, `notification-clear-history`. Verified from upstream `src/app/application_ipc.cpp` + per-service `registerIpc` calls.
3. **lid-close** triggers Noctalia lock via `noctalia msg session lock`
4. **layer-rules** place the Noctalia overview within backdrop (namespace `^noctalia-overview.*`)
5. **v4 → v5 verb migration** — old `noctalia-shell ipc call X Y` became `noctalia msg <x-y>`. Notable: `lockScreen lock` → `session lock`; `darkMode toggle` → `theme-mode-toggle`; `volume muteInput` → `mic-mute`; `media playPause` → `media play-pause`.

## Dependencies

- **Imports**: Stylix (cursor theme/size), constants, hostname
- **Imported by**: `home/desktop/default.nix`
