# Bluetooth: BlueZ + Blueman.
{ pkgsStable, ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Blueman Bluetooth manager
  services.blueman.enable = true;

  environment.systemPackages = with pkgsStable; [ blueman ];
}
