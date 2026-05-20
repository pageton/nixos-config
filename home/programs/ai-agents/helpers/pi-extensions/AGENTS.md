# Pi Extension: Git Checkpoint

1 file, 325 lines. TypeScript extension for Pi coding agent — git checkpoint create/list/restore tools.

## Files

| File                | Purpose                                          |
| ------------------- | ------------------------------------------------ |
| `git-checkpoint.ts` | Git checkpoint create/list/restore tools for omp |

## Conventions

- TypeScript extension — not a Nix module
- Used by Pi via `PI_CODING_AGENT_DIR` env var
- Part of `helpers/` — not a standalone module

## Dependencies

- Parent: `home/programs/ai-agents/helpers/` (imports via `_pi-profiles.nix`)
