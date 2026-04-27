# Language Toolchains

Programming language runtimes, LSP servers, and version management. Each file configures a specific language ecosystem.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Imports all language modules |
| `go.nix` | Go toolchain, env vars, aliases |
| `javascript.nix` | JS/TS tooling, LSP servers, aliases |
| `python.nix` | Python tooling, LSP servers, aliases |
| `lsp-servers.nix` | Cross-language LSP servers for editors |
| `mise.nix` | Mise polyglot runtime manager (replaces asdf) |

## Conventions

- Each language gets its own file with toolchain packages, env vars, and shell aliases
- LSP servers are centralized in `lsp-servers.nix` for editor consumption
- Mise manages runtime versions not available in nixpkgs

## Dependencies

- **Imported by**: `home/programs/default.nix`
- **Used by**: `home/programs/nvf/` (LSP servers for Neovim)
