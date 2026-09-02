# Noctalia v5 package wiring + runtime dependencies.
# The HM module (inputs.noctalia.homeModules.default) installs the `noctalia`
# binary when programs.noctalia.enable = true; no manual package install needed.
_: {
  programs.noctalia.enable = true;

  # Runtime deps not bundled by the noctalia package. v5 ships its own clipboard
  # manager (shell.clipboard_enabled); cliphist + wl-clipboard + wl-clip-persist
  # are provided by home/packages/wayland.nix (pkgsStable) and back the niri
  # spawn-at-startup Wayland-clipboard watchers. Do NOT re-add wl-clipboard here
  # — a second copy via `pkgs` (unstable) collides with the stable one in buildEnv.
}
