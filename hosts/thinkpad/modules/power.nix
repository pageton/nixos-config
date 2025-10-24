# Power management and performance configuration for ThinkPad.
# This module configures power management settings optimized for ThinkPad
# laptops, including thermal throttling prevention and power profiles.

{ lib, ... }:

{
  # Enable NixOS power management
  powerManagement.enable = true;

  # Game mode configuration
  # Disabled to prevent automatic CPU governor changes during gaming
  programs.gamemode.enable = false;

  services = {
    # Disable power-profiles-daemon to avoid conflicts with TLP
    power-profiles-daemon.enable = false;

    # Enable ThinkPad throttling prevention daemon
    # Helps prevent thermal throttling on ThinkPad laptops
    throttled.enable = lib.mkDefault true;

    # Enable auto-cpufreq for better CPU frequency control
    # Works well with TLP on ThinkPads for optimal battery life
    auto-cpufreq.enable = lib.mkDefault true;
  };

  # ThinkPad-specific kernel modules for battery control
  boot.kernelModules = [
    "acpi_call"
    "tp_smapi"
    "thinkpad_acpi"
  ];
}
