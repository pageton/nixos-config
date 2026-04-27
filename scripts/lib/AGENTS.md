# Shared Shell Libraries

Sourced bash helper libraries used across all `scripts/` subdirectories. These files are sourced (not executed), so they omit `set -euo pipefail`.

## Files

| File | Purpose |
|------|---------|
| `logging.sh` | Shared logging functions (info, warn, error, success). Sourced by almost all scripts |
| `test-helpers.sh` | Assertion functions for `*-test.sh` files (assert_eq, assert_contains, assert_exit) |
| `fzf-theme.sh` | Catppuccin Mocha fzf color theme. Sourced by agent-launcher, agent-inventory, agent-dashboard |
| `error-patterns.sh` | Error pattern matching for log analysis. Sourced by agent-analyze, report-collectors-core |
| `require.sh` | Dependency checker (verify commands exist). Sourced by android-re helpers |
| `log-dirs.sh` | Log directory constants and path resolution for AI agent logs |
| `awk-utils.awk` | Shared AWK utility functions |
| `extract-nix-shell.awk` | AWK script to extract inline shell from Nix files for shellcheck |

## Conventions

- Library files are sourced, never executed directly
- Omit `set -euo pipefail` (caller sets error handling)
- `logging.sh` must be sourced first — other libs may call logging functions
- AWK files (`.awk`) are called by shell scripts, not sourced

## Dependencies

- **Used by**: Almost all `scripts/**/*.sh` files source at least `logging.sh`
