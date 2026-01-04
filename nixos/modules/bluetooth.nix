# Bluetooth configuration module.
{
  config,
  lib,
  pkgsStable,
  ...
}: {
  # Custom module options for Bluetooth configuration
  options.mySystem.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support with Blueman manager";

    powerOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Power on Bluetooth adapter automatically at boot";
    };
  };

  # Configuration applied when Bluetooth is enabled
  config = lib.mkIf config.mySystem.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      inherit (config.mySystem.bluetooth) powerOnBoot;
    };

    # Enable Blueman Bluetooth manager service
    services.blueman.enable = true;

    # Install Bluetooth management utilities
    environment.systemPackages = with pkgsStable; [blueman];
  };
}
