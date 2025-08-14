# Main NixOS configuration for the 'pc' host.

{
  pkgs,
  stateVersion,
  hostname,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
    ./modules
    ../../themes/catppuccin.nix
  ];

  networking.hostName = hostname;

  system = {
    inherit stateVersion;
  };

  mySystem.gaming = {
    enable = true;
    enableGamescope = true;
  };

  environment.systemPackages = with pkgs; [
    home-manager
  ];
}
