# SOPS Secrets Editing

2 files, 113 lines. SOPS age-encrypted secret management helpers.

## Files

| File                  | Purpose                                           |
| --------------------- | ------------------------------------------------- |
| `sops-edit.sh`        | Secrets editor (RAM-backed tmpfs, age encryption) |
| `editor-code-wait.sh` | VS Code wait wrapper for sops editing             |

## Conventions

- Uses tmpfs-backed editing (`$XDG_RUNTIME_DIR`)
- If interrupted, OS reclaims automatically

## Dependencies

- Sourced by: `justfile` (`just sops-edit`)
- Requires: `sops-nix`, `age` keys in `~/.config/sops/age/`
