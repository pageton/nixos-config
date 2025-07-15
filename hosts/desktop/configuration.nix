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
    ../../themes/catppuccin.nix
  ];

  networking.hostName = hostname;

  system = {
    inherit stateVersion;
    autoUpgrade.enable = true;
    autoUpgrade.dates = "weekly";
  };

  environment.systemPackages = [ pkgs.home-manager ];
}
