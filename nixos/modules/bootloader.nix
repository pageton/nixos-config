# Bootloader configuration (GRUB - no theme).

{
  boot.loader = {
    # Disable systemd-boot
    systemd-boot.enable = false;

    # Enable GRUB
    grub = {
      enable = true;
      device = "nodev"; # Use UEFI boot
      efiSupport = true;
      # For UEFI systems, we need to allow touching EFI variables
      efiInstallAsRemovable = false;
    };

    # Allow touching EFI variables for UEFI systems
    efi.canTouchEfiVariables = true;
  };
}
