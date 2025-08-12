# Imports all NixOS modules.

{
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./bootloader.nix
    ./nautilus.nix
    ./environment.nix
    ./gaming.nix
    ./sddm.nix
    ./graphics.nix
    ./hyprland.nix
    ./i18n.nix
    ./libinput.nix
    ./networking.nix
    ./nix-ld.nix
    ./nix.nix
    ./timezone.nix
    ./tor.nix
    ./upower.nix
    ./users.nix
    ./xserver.nix
  ];
}
