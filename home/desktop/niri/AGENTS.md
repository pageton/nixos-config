# Niri Compositor Configuration

Niri scrollable-tiling Wayland compositor — Home Manager configuration split into focused sub-modules for keybinds, layout, window rules, animations, idle behavior, screen locking, and input handling.

## Files

| File              | Purpose                                                                                |
| ----------------- | -------------------------------------------------------------------------------------- |
| `default.nix`     | Main config: environment vars, spawn-at-startup, cursor, debug, layer-rules, lid-close |
| `bindings.nix`    | Keyboard shortcuts and keybind actions                                                 |
| `layout.nix`      | Window layout rules, column widths, gaps, struts                                       |
| `rules.nix`       | Per-window/open rules (floating, fullscreen, workspace assignment)                     |
| `animations.nix`  | Transition and motion animations                                                       |
| `idle.nix`        | DMS idle timeouts (lock, screen off, lock before suspend)                              |
| `lock.nix`        | DMS lock-screen and loginctl integration                                               |
| `input.nix`       | Keyboard, mouse, touchpad, trackpoint settings                                         |
| `_auth-float.nix` | Auth dialog floating window rule (private/internal)                                    |

## Conventions

- Each concern is a separate `.nix` file imported by `default.nix`
- Files prefixed with `_` are internal/private helpers
- Host-specific behavior uses `isThinkpad` conditional (cursor size differences)
- `spawn-at-startup` launches niri-auth-float and wl-clip-persist; DMS is managed by its Home Manager systemd service

## Gotchas

1. **Niri flake does NOT follow nixpkgs** — pinned mesa for GPU compatibility; do not change this
2. **lid-close** triggers DMS lock via IPC (`dms ipc call lock lock`)
3. **layer-rules**: the previous Noctalia overview backdrop rule was dropped — DMS renders its launcher/overview as a modal. Re-add a rule only after confirming the DMS layer namespace via `niri msg layers`.
4. **We deliberately do NOT import DMS's `homeModules.niri`** — it `lib.mkForce`'s the niri config target and would clobber this hand-written config tree.

## Dependencies

- **Imports**: Stylix (cursor theme/size), constants, hostname
- **Imported by**: `home/desktop/default.nix`
