# Niri scrollable-tiling Wayland compositor.
# Requires inputs.niri.nixosModules.niri in flake modules.
{
  lib,
  inputs,
  hostname,
  ...
}: {
  nixpkgs.overlays = [inputs.niri.overlays.niri];

  programs.niri = lib.mkIf (hostname != "server") {
    enable = true;
  };
}
