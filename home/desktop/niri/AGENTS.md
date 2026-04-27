# Niri Compositor Configuration

Niri scrollable-tiling Wayland compositor — Home Manager configuration split into focused sub-modules for keybinds, layout, window rules, animations, idle behavior, screen locking, and input handling.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Main config: environment vars, spawn-at-startup, cursor, debug, layer-rules, lid-close |
| `bindings.nix` | Keyboard shortcuts and keybind actions |
| `layout.nix` | Window layout rules, column widths, gaps, struts |
| `rules.nix` | Per-window/open rules (floating, fullscreen, workspace assignment) |
| `animations.nix` | Transition and motion animations |
| `idle.nix` | Idle timeout actions (dim, lock, screen off) |
| `lock.nix` | Screen lock configuration |
| `input.nix` | Keyboard, mouse, touchpad, trackpoint settings |
| `_auth-float.nix` | Auth dialog floating window rule (private/internal) |

## Conventions

- Each concern is a separate `.nix` file imported by `default.nix`
- Files prefixed with `_` are internal/private helpers
- Host-specific behavior uses `isThinkpad` conditional (cursor size differences)
- `spawn-at-startup` launches: niri-auth-float, dbus env, noctalia-shell, xwayland-satellite, cliphist, wl-clip-persist

## Gotchas

1. **Niri flake does NOT follow nixpkgs** — pinned mesa for GPU compatibility; do not change this
2. **lid-close** triggers noctalia-shell lock via IPC
3. **layer-rules** place Noctalia overview within backdrop

## Dependencies

- **Imports**: Stylix (cursor theme/size), constants, hostname
- **Imported by**: `home/desktop/default.nix`
