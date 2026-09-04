# Desktop environment system configs — compositor, shell, theming, and integration.
{ ... }: {
  imports = [
    ./niri # Niri compositor keybinds, layouts, window rules, startup
    ./noctalia # Noctalia v5 shell: bar, launcher, control center, notifications
    ./qt # Qt Wayland integration and theme settings
    ./mime # Default application associations (MIME types)
    ./cloudflare-warp # WARP tray GUI (matches mySystem.cloudflareWarp)
    ./udiskie # Auto-mount removable media with notifications
  ];
}
