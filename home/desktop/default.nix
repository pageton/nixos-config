# Desktop environment system configs — compositor, shell, theming, and integration.
{ ... }:
{
  imports = [
    ./niri # Niri compositor keybinds, layouts, window rules, startup
    ./noctalia # Noctalia shell: bar, launcher, control center, notifications
    ./qt # Qt Wayland integration and theme settings
    ./mime # Default application associations (MIME types)
    ./udiskie # Auto-mount removable media with notifications
  ];
}
