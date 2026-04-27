---
name: init
description: Initialize project context by creating AGENTS.md with architecture overview, conventions, and key file documentation.
---

# Project Init

Initialize a new project by creating or updating `AGENTS.md` in the current directory.

## Steps

1. **Scan the project structure** — read the top-level directory tree, identify:
   - Language(s) and framework(s)
   - Build system and package manager
   - Entry points and main modules
   - Test and config directories
   - Existing documentation

2. **Read key files** to understand conventions:
   - `README.md`, `CONTRIBUTING.md`, `justfile`, `Makefile`, `package.json`, `flake.nix`, `Cargo.toml`, `go.mod`, `pyproject.toml` (whichever exist)
   - Lint/format config (`.editorconfig`, `biome.json`, `.prettierrc`, `statix.toml`)
   - CI/CD config (`.github/workflows/`, `ci/`)

3. **Generate `AGENTS.md`** with these sections:
   - **Role** — one-line description of the project
   - **Architecture** — directory structure with purpose of each top-level dir
   - **Key Files** — table of important files and what they do
   - **Conventions** — coding style, naming patterns, commit format, branch strategy
   - **Build & Test** — exact commands to build, test, lint, format
   - **Gotchas** — known issues, circular deps, fragile areas
   - **Dependencies** (optional) — map of key internal modules and their relationships

4. **Keep it concise** — the goal is a quick reference for AI agents, not exhaustive documentation. Target 50-150 lines.

5. **Do not overwrite** existing `AGENTS.md` without asking. Offer to merge or update sections instead.

## Guidelines

- Distinguish verified facts (from reading actual files) from inference.
- Use file paths as evidence — cite specific files for every claim.
- If the project already has good docs, extract and reference them rather than duplicating.
