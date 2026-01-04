# Libinput configuration.
# This module enables libinput for advanced input device support,
# providing better touchpad, mouse, and touch device handling.
{
  lib,
  hostname,
  ...
}: {
  services.libinput.enable = lib.mkDefault (hostname != "server"); # Enable libinput for workstations
}