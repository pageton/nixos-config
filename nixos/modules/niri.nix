# Niri scrollable-tiling Wayland compositor.
# Requires inputs.niri.nixosModules.niri in flake modules.
{
  inputs,
  ...
}: {
  nixpkgs.overlays = [inputs.niri.overlays.niri];

  programs.niri = {
    enable = true;
  };
}
