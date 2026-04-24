# Main NixOS configuration for the 'desktop' host.
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
  ];

  networking.hostName = hostname;

  system = { inherit stateVersion; };

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
      enableWrappedBinaries = true;
    };
    bluetooth = {
      enable = false;
      powerOnBoot = false;
    };
    flatpak = {
      enable = true;
    };
    tor = {
      enable = true;
    };
    dnscryptProxy = {
      enable = false;
    };
    netdata = {
      enable = true;
    };
    scrutiny = {
      enable = true;
    };
    syncthing = {
      enable = true;
    };
    glance = {
      enable = true;
    };
    macchanger = {
      enable = true;
    };
    mullvadVpn = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [ home-manager ];
}
