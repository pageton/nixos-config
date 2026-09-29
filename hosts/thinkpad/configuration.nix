# Main NixOS configuration for the 'thinkpad' host.
# Laptop: Intel iGPU + NVIDIA dGPU (PRIME offload), TLP power management.
{
  lib,
  stateVersion,
  hostname,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ./modules
    ../../nixos/profiles/common.nix
  ];

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  # Laptop: don't power the Bluetooth adapter at boot.
  hardware.bluetooth.powerOnBoot = lib.mkForce false;
}
