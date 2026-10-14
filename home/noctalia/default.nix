# Noctalia v5 — native C++ desktop shell (ACTIVE).
# Replaces both the v4 Quickshell shell and the DankMaterialShell experiment.
# v5 uses TOML config (~/.config/noctalia/) + a GUI state layer
# (~/.local/state/noctalia/settings.toml).
#
# The HM module (inputs.noctalia.homeModules.default) installs the `noctalia`
# binary when programs.noctalia.enable = true; no manual package install needed.
#
# Runtime deps not bundled by the noctalia package. v5 ships its own clipboard
# manager (shell.clipboard_enabled); cliphist + wl-clipboard + wl-clip-persist
# are provided by home/packages/wayland.nix (pkgsStable) and back the niri
# spawn-at-startup Wayland-clipboard watchers. Do NOT re-add wl-clipboard here
# — a second copy via `pkgs` (unstable) collides with the stable one in buildEnv.

# home-manager master ships its own programs.noctalia module (a directory:
# modules/programs/noctalia/default.nix) that duplicates the options in
# inputs.noctalia's nix/home-module.nix, causing "option already declared"
# errors. Upstream noctalia tries to disable it via
# disabledModules = [ "programs/noctalia.nix" ] but that path is stale since
# HM moved the module into a directory. Until noctalia-dev/noctalia fixes the
# path, disable HM's built-in here so the noctalia flake's module (richer:
# customPalettes, systemd, validateConfig rename) wins.
#
# NOTE: the disabledModules string must match the module's key exactly as HM
# lists it in modules/modules.nix — the auto-discovered programs tree imports
# the *directory* `programs/noctalia` (key: "programs/noctalia"), not
# "programs/noctalia/default.nix". Both forms are listed to stay robust if
# upstream moves back to a single file.
_: {
  disabledModules = [
    "programs/noctalia"
    "programs/noctalia.nix"
  ];

  programs.noctalia.enable = true;

  imports = [
    ./settings.nix # theme + wallpaper + bar defaults (Nix attrset -> TOML)
  ];
}
