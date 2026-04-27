# Neovim (NVF Framework)

Neovim configuration via the NVF framework — modular setup with LSP, completion, languages, bindings, and utility plugins.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Entry point: imports nvf homeManagerModule + all sub-modules |
| `options.nix` | Top-level vim options (leader key, config prefix) |
| `lsp.nix` | LSP server configuration (autocomplete, diagnostics) |
| `languages.nix` | Language-specific settings (treesitter, formatters) |
| `completion.nix` | Autocompletion (nvim-cmp) and snippet engine |
| `bindings.nix` | Key mappings and leader bindings |
| `snacks.nix` | Snacks plugin suite |
| `utils.nix` | Utility plugins (telescope, which-key, etc.) |
| `mini.nix` | mini.nvim plugin suite |
| `KEYBINDINGS.md` | Keybinding reference document |

## Conventions

- All config goes through `programs.nvf.settings.vim.*` options
- Extra plugins via `startPlugins` or `luaPackages` in default.nix
- External plugins referenced from `pkgs.vimPlugins.*`

## Dependencies

- **Inputs**: `nvf` flake input
- **Imported by**: `home/programs/default.nix`
