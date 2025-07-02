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

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-uuid/66CC-B6EC";
    fsType = "exfat";
    options = [
      "nofail"
      "users"
      "rw"
      "uid=1000"
      "gid=100"
    ];
  };

  environment.systemPackages = [ pkgs.home-manager ];
}
