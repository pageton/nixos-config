# Niri scrollable tiling Wayland compositor.
{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.niri.nixosModules.niri ];

  # Add niri overlay for mesa compatibility
  nixpkgs.overlays = [
    # libdisplay-info_0_2 was removed from nixpkgs-unstable but niri requires
    # exactly 0.2.0. Bridge from niri's pinned nixpkgs (see flake.nix niri input).
    (_final: prev: {
      libdisplay-info_0_2 = inputs.niri.inputs.nixpkgs.legacyPackages.${prev.system}.libdisplay-info_0_2;
    })
    inputs.niri.overlays.niri
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  # XWayland compatibility via xwayland-satellite
  environment.systemPackages = [ pkgs.xwayland-satellite ];

  # Security services for compositor
  security.polkit.enable = true;

  # niri-flake's user service runs outside the compositor session on this host,
  # causing polkit-gnome to loop with "No session for pid". Start the agent
  # from Niri startup (home/desktop/niri/default.nix) instead.
  systemd.user.services.niri-flake-polkit.enable = lib.mkForce false;
}
