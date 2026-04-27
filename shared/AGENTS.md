# Shared Nix Helpers

Cross-boundary Nix expressions used by both NixOS system modules and Home-Manager user modules. Imported directly by `flake.nix` and passed via `specialArgs`.

## Files

| File | Purpose |
|------|---------|
| `constants.nix` | SSOT: user identity, fonts, Catppuccin Mocha colors, keyboard layout, service ports, proxy endpoints, paths |
| `option-helpers.nix` | Typed NixOS option constructors: `mkBoolOption`, `mkStrOption`, `mkIntOption`, `mkEnumOption` |
| `alias-helpers.nix` | Shared shell alias definitions injected into both zsh and bash configs |
| `secret-loader.nix` | Bash function `_load_secret()` to read SOPS-decrypted secrets from `/run/secrets/` |

## Conventions

- `constants.nix` is the single source of truth — never hardcode values that belong here
- Passed to all modules via `specialArgs.constants` (set in `flake.nix`)
- `secret-loader.nix` is a bash file sourced by zsh config and ai-agent scripts
- `option-helpers.nix` reduces boilerplate in NixOS module option definitions

## Dependencies

- **Imported by**: `flake.nix` → propagated to all NixOS and HM modules via `specialArgs`
- **Consumed by**: virtually every module in the repository
