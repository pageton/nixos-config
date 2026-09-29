# Laptop power management and kernel modules.
{ pkgs, ... }:
{
  powerManagement.enable = true;

  services = {
    power-profiles-daemon.enable = false; # Conflicts with TLP
  };

  boot.kernelModules = [
    "acpi_call"
    "thinkpad_acpi"
    "tp_smapi"
  ];

  # ThinkPad battery utilities
  environment.systemPackages = [ pkgs.tpacpi-bat ];
}
