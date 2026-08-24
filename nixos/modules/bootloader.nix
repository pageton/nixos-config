# Bootloader configuration (GRUB - no theme).
{ pkgs, ... }: {
  boot.kernelPackages = pkgs.linuxPackages_6_18;

  boot.loader = {
    systemd-boot.enable = false;

    efi = {
      canTouchEfiVariables = true;
    };

    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = false;
    };
  };
}
