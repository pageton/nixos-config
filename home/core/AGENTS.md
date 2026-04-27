# Home Core Modules

Base Home-Manager modules for user identity, session environment, desktop integration, and activation scripts.

## Files

| File | Purpose |
|------|---------|
| `default.nix` | Imports all core sub-modules |
| `user.nix` | Username, homeDirectory, stateVersion, base packages, fonts |
| `session.nix` | Session variables (Qt/GTK/Electron Wayland), telemetry opt-out |
| `desktop-entries.nix` | Custom `.desktop` files for firejail-wrapped apps |
| `gtk-dconf.nix` | Dark theme preference, privacy settings (no recent files tracking) |
| `activation.nix` | Custom HM activation script (nix profile management) |

## Conventions

- These run for every host — no `mySystem.*` opt-in needed
- `user.nix` establishes the base home.sessionVariables and home.packages
- Desktop entries here are for apps that need custom launchers (e.g., sandboxed browser wrappers)

## Dependencies

- **Imported by**: `home/home.nix`
