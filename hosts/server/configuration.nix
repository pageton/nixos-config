# NixOS server configuration with disko + UEFI GRUB on /dev/sda
{
  modulesPath,
  stateVersion,
  hostname,
  ...
}: {
  imports = [
    # Auto-detected hardware helpers
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")

    # Declarative disk layout for /dev/sda
    ./disk-config.nix
    ./hardware-configuration.nix
    ../../nixos/modules
  ];

  networking.hostName = hostname;

  mySystem = {
    nginx.enable = true;
    bitwarden.enable = true;
    postgresql = {
      enable = true;
      enableTCPIP = true;
    };
  };

  system.stateVersion = stateVersion;
}
