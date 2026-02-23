# Libinput configuration.
# This module enables libinput for advanced input device support,
# providing better touchpad, mouse, and touch device handling.
{...}: {
  services.libinput.enable = true;
}