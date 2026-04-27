# Home Build Scripts

User-level build and audit helper scripts installed via Home-Manager. Wraps the system-level `scripts/build/` scripts for convenient user-space access.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Imports all build sub-modules |
| `eval-audit.nix` | Nix evaluation timing audit script |
| `hardening-audit.nix` | Systemd service hardening report |
| `modules-check.nix` | Verify all .nix files are imported by parent default.nix |
| `performance-audit.nix` | Boot/session performance diagnostics |
| `security-audit.nix` | Security-focused repository checks |

## Conventions

- Each script is a standalone bash script managed as a Home-Manager file
- Scripts mirror `scripts/build/` functionality but are available in user PATH

## Dependencies

- **Imported by**: `home/scripts/default.nix`
