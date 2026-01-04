# Udiskie is a simple daemon that uses udisks to automatically mount removable storage devices.
{pkgs, ...}: {
  services.udiskie = {
    enable = true;
    notify = true;
    automount = true;
    tray = "auto";
  };
}
