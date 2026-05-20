# Shared Nix Helpers

Cross-boundary Nix expressions used by both NixOS system modules and Home-Manager user modules. Imported directly by `flake.nix` and passed via `specialArgs`.

## Files

| File | Purpose |
|------|---------|
| `constants.nix` | SSOT: user identity, fonts, Catppuccin Mocha colors, keyboard layout, service ports, proxy endpoints, paths |
| `option-helpers.nix` | Typed NixOS option constructors: `mkBoolOption`, `mkStrOption`, `mkIntOption`, `mkEnumOption` |
| `alias-helpers.nix` | Shared shell alias definitions injected into both zsh and bash configs |
| `_hm-systemd-helpers.nix` | Shared Home-Manager systemd timer helpers: `mkHmTimer`, `mkWeeklyTimer` |
## Directory Structure

```
shared/
├── constants.nix      # SSOT: user, fonts, colors, keyboard, ports, proxies
├── option-helpers.nix # Typed NixOS option constructors
├── alias-helpers.nix  # Shared shell alias injection (zsh + bash)
└── _hm-systemd-helpers.nix # Shared HM systemd timer helpers
```

## Conventions

- `constants.nix` is the single source of truth — never hardcode values that belong here
- Passed to all modules via `specialArgs.constants` (set in `flake.nix`)
- `secret-loader.nix` was moved to `home/_helpers/` — it is only used by HM modules
- `option-helpers.nix` reduces boilerplate in NixOS module option definitions
- `_hm-systemd-helpers.nix` is imported directly by `flake.nix` (not via specialArgs) and provides timer factories for HM service modules

## Dependencies

- **Imported by**: `flake.nix` → propagated to all NixOS and HM modules via `specialArgs`
- **Consumed by**: virtually every module in the repository
