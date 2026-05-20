# Zellij Terminal Multiplexer

4 files, 383 lines. Zellij config + TUI extension.

## Files

| File          | Purpose                               |
| ------------- | ------------------------------------- |
| `default.nix` | Import hub                            |
| `zellij.nix`  | Zellij config + TUI extension loading |
| `_.sh`        | Shared helpers                        |
| `_.nix`       | Extension helpers                     |

## Conventions

- Follows `terminal/` subdirectory pattern
- TUI extension loaded via `helpers/_zellij-tui.nix`

## Dependencies

- Imported by: `home/programs/terminal/default.nix`
- Receives: `pkgs`, `pkgsStable`, `constants` via specialArgs
