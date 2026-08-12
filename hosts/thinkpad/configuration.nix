# Main NixOS configuration for the 'thinkpad' host.
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

  mySystem = {
    virtualisation.enable = false;
    gaming = {
      enable = false;
      enableGamescope = false;
    };
    sandboxing = {
      enable = true;
      enableUserNamespaces = true;
      enableWrappedBinaries = true;
    };
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
    flatpak = {
      enable = true;
    };
    dnscryptProxy = {
      enable = false;
    };
    amdRyzenThermal = {
      enable = false;
    };
    mullvadVpn = {
      enable = false;
    };
    webRe = {
      enable = false;
    };
    cloudflared = {
      enable = false;
    };
    vaultwarden = {
      enable = false;
    };
    tailscale = {
      enable = true;
    };
    tor = {
      enable = true;
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
    codex = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [ home-manager ];
}
