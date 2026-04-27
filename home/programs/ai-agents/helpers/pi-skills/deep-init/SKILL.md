---
name: deep-init
description: Deep project initialization — recursive codebase scan producing AGENTS.md in root AND every major subdirectory, each scoped to its contents.
---

# Deep Project Init (Recursive)

Perform a thorough deep-scan of the project to produce **recursive AGENTS.md files** — one in the project root and one in every major subdirectory. Each AGENTS.md is scoped to its directory's contents only.

This matches how Claude Code, OpenCode, and other tools use nested knowledge files for context-aware agent behavior.

## Steps

1. **Full directory tree scan** — map the complete project structure, identify:
   - All source directories and their purposes
   - Config directories and their schemas
   - Test directories (unit, integration, e2e)
   - Generated/build output directories
   - Scripts and tooling
   - Documentation

2. **Read ALL key files** — not just top-level:
   - Build system configs (all of them)
   - Dependency manifests (`package.json`, `Cargo.toml`, `go.mod`, `flake.nix`, `requirements.txt`)
   - Lint, format, and type-check configs
   - CI/CD pipeline definitions
   - Entry points and main modules
   - Shared utilities and helpers
   - Test setup and fixtures
   - Environment and secret management

3. **Dependency analysis**:
   - Internal module dependency graph (which modules import which)
   - External dependency list with versions
   - Circular dependency detection
   - Shared type/interface definitions

4. **Data flow mapping**:
   - Request/response flows (API endpoints, handlers, services)
   - State management patterns
   - Database schema and migrations
   - Event/message flows
   - Configuration propagation

5. **Module boundary identification**:
   - Clear ownership boundaries between modules
   - Public APIs vs internal implementation
   - Shared contracts and interfaces
   - Integration points and coupling

6. **Risk area assessment**:
   - Fragile or complex code paths
   - High-churn files (from git history if available)
   - Performance-sensitive areas
   - Security-sensitive areas (auth, secrets, input validation)
   - Untested or undertested areas

7. **Generate root `AGENTS.md`** — project-wide overview with:
   - **Role** — project description
   - **Architecture** — full directory structure with purpose
   - **Key Files** — detailed table with file paths and descriptions
   - **Module Map** — internal module boundaries and ownership
   - **Data Flow** — how data moves through the system
   - **Dependencies** — internal graph + external versions
   - **Conventions** — coding style, naming, commits, branches, PR workflow
   - **Build & Test** — exact commands with expected outputs
   - **Gotchas** — known issues, circular deps, fragile areas, breaking change risks
   - **Security Considerations** — auth flows, secret handling, trust boundaries

8. **Generate subdirectory AGENTS.md files** — for each major subdirectory:
   - Scan files within that directory only
   - Generate a scoped AGENTS.md covering:
     - **Purpose** — what this directory contains
     - **Files** — table of files with descriptions
     - **Dependencies** — what this module imports and what imports it
     - **Conventions** — directory-specific patterns
     - **Gotchas** — directory-specific issues
   - Directories to include (skip directories with < 5 files or only generated content):
     - `src/`, `lib/`, `pkg/`, `internal/`, `cmd/`, `api/`, `web/`, `nixos/`, `home/`, `scripts/`, `shared/`, `helpers/`, `config/`, `activation/`, or any directory with > 5 source files
   - Do NOT generate AGENTS.md inside `node_modules/`, `.git/`, `build/`, `dist/`, or vendor directories

9. **Validation** — after generating ALL files, verify:
   - All file paths mentioned actually exist
   - Build commands work (run them if possible)
   - No fabricated information — every claim has a source file

## Guidelines

- This is a READ-ONLY operation. Do NOT modify any files except `AGENTS.md`.
- Distinguish verified facts from inference — mark inferred sections clearly.
- Use exact file paths as evidence for every claim.
- If the project is too large for full scan, prioritize entry points, shared modules, and config.
- Root AGENTS.md: target 150-300 lines — comprehensive but scannable.
- Subdirectory AGENTS.md: target 30-80 lines — focused and useful.
- Offer to create a lighter root `AGENTS.md` via `/skill:init` if this is too much.
- Skip subdirectories that already have an AGENTS.md that looks complete (check first line for header comment).
