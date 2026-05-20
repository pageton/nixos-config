# Noctalia Shell/Bar/Plugins

4 files, 233 lines. Noctalia integration: shell, bar, plugins, control center, notifications for Niri.

## Files

| File           | Purpose                    |
| -------------- | -------------------------- |
| `default.nix`  | Import hub                 |
| `noctalia.nix` | Shell/bar/plugins config   |
| `_.nix`        | Systemd services for noMan |
| `_.sh`         | Shared Noctalia helpers    |

## Conventions

- Noctalia is the default shell/launcher for Niri
- Plugins loaded via `noctalia.nix` config

## Dependencies

- Imported by: `home/desktop/default.nix`
- Receives: `pkgs`, `constants` via specialArgs
