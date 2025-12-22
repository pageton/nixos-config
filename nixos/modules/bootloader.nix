# Bootloader configuration (GRUB - no theme).
{
  lib,
  hostname,
  ...
}: {
  # Bootloader configuration conditional on hostname
  # This section ensures that server and non-server machines have different GRUB/systemd-boot settings
  boot.loader = lib.mkForce (
    if hostname == "server"
    then {
      # UEFI GRUB bootloader on GPT disk for server
      # No need to manually set devices, disko will automatically include all EF02 partitions
      grub = {
        enable = true; # Enable GRUB
        efiSupport = true; # Enable EFI support
        efiInstallAsRemovable = true; # Install as removable device for UEFI
      };
      # Note: This config ensures the server is bootable with GPT and UEFI without touching device nodes
    }
    else {
      # Bootloader for non-server machines
      # Standard UEFI GRUB configuration
      systemd-boot.enable = false; # Disable systemd-boot to avoid conflicts
      grub = {
        enable = true; # Enable GRUB
        device = "nodev"; # Use UEFI boot without specifying a device
        efiSupport = true; # EFI support for non-server machines
        efiInstallAsRemovable = false; # Do not install as removable device
      };
      # Allow touching EFI variables for non-server UEFI systems
      efi.canTouchEfiVariables = true;
      # Note: This preserves traditional UEFI bootloader behavior on desktops/laptops
    }
  );
}
