# Main NixOS configuration for the 'pc' host.
{
  pkgs,
  stateVersion,
  hostname,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
    ./modules
  ];

  networking.hostName = hostname;

  system = {inherit stateVersion;};

  # System module configurations with all options explicitly set
  mySystem = {
    virtualisation.enable = true;
    gaming = {
      enable = true;
      enableGamescope = true;
    };
    sandboxing = {
      enable = true;
      enableUserNamespaces = true;
      enableWrappedBinaries = false;
    };
    bluetooth = {
      enable = false;
      powerOnBoot = false;
    };
    flatpak = {
      enable = true;
    };
    mullvadVpn = {
      enable = true;
    };
    tor = {
      enable = true;
    };
    dnscryptProxy = {
      enable = true;
    };
    macchanger = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [home-manager];
}
