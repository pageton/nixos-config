# Bluetooth configuration.
{
  lib,
  hostname,
  pkgsStable,
  ...
}:
lib.mkIf (hostname != "server") {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };

  services.blueman.enable = true;

  environment.systemPackages = with pkgsStable; [blueman];
}
