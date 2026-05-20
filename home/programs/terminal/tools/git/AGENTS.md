# Git Tools

3 files, 288 lines. Git workflow helpers: checkout, branch, sync, undo, stash.

## Files

| File          | Purpose                          |
| ------------- | -------------------------------- |
| `default.nix` | Import hub                       |
| `git.nix`     | Git aliases + workflow functions |
| `_.sh`        | Shared git helper functions      |

## Conventions

- Follows `terminal/tools/` subdirectory pattern
- Uses `fzf` for interactive selection

## Dependencies

- Imported by: `home/programs/terminal/tools/default.nix`
- Receives: `pkgs` via specialArgs
