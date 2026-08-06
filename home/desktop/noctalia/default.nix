# Noctalia v5 — native C++ desktop shell (ACTIVE).
# Replaces both the v4 Quickshell shell and the DankMaterialShell experiment.
# v5 uses TOML config (~/.config/noctalia/) + a GUI state layer
# (~/.local/state/noctalia/settings.toml); see home/desktop/AGENTS.md.
{ ... }: {
  imports = [
    ./packages.nix # programs.noctalia enable + package wiring
    ./settings.nix # theme + wallpaper + bar defaults (Nix attrset -> TOML)
  ];
}
