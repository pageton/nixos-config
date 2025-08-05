{ inputs, pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = inputs.hyprland.packages."${pkgs.system}".hyprland;

    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  # Enable security services
  security = {
    polkit.enable = true;
    pam.services = {
      hyprlock = { };
      gdm.enableGnomeKeyring = true;
    };
  };
}
