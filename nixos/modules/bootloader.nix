# Bootloader configuration (GRUB - no theme).
{
  lib,
  hostname,
  ...
}: {
  boot.loader = lib.mkForce (
    if hostname == "server"
    then {
      # Server: GRUB UEFI GPT optimized
      systemd-boot.enable = false;
      grub = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = true; # Dual boot safe
      };
    }
    else {
      # Desktop/ThinkPad: GRUB UEFI standard
      systemd-boot.enable = false;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        efiInstallAsRemovable = false; # Traditional UEFI
      };
      efi.canTouchEfiVariables = true;
    }
  );
}