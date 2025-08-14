# Bluetooth configuration.

{ pkgsStable, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  services.blueman.enable = true;

  environment.systemPackages = with pkgsStable; [ blueman ];
}
