# DankMaterialShell — Shell/Bar/Launcher

3 files. DMS integration: bar, launcher (spotlight), notifications, control center,
lock screen, power menu, clipboard, OSD, and dynamic (matugen) theming for Niri.

## Files

| File           | Purpose                                            |
| -------------- | -------------------------------------------------- |
| `default.nix`  | `programs.dank-material-shell` enable + settings   |
| `packages.nix` | Runtime deps not bundled by dms-shell (OCR/scan/…) |
| `AGENTS.md`    | This file                                          |

## Conventions

- DMS is the default shell/launcher for Niri (replaced Noctalia 2026-08-05).
- Config written to `~/.config/DankMaterialShell/settings.json` by the HM module.
- IPC: `dms ipc call <target> <action>` (spotlight, notifications, settings,
  control-center, powermenu, lock, clipboard, processlist, audio, brightness,
  mpris, theme, night, wallpaper, bar, dash, notepad, color-picker).
- We deliberately do NOT import DMS's `homeModules.niri` — it mkForce's the niri
  config target and would clobber `home/desktop/niri/`. Niri wiring is manual.

## Dependencies

- Imported by: `home/desktop/default.nix`
- Flake input: `dank-material-shell` (follows nixpkgs)
- HM module: `inputs.dank-material-shell.homeModules.dank-material-shell`
