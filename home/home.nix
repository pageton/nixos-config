# Home-Manager entry point — imports all sub-modules.
# Actual packages are set by core/user.nix via home.packages.
{ ... }: {
  imports = [
    ./ai
    ./core
    ./programs
    ./niri # Niri compositor keybinds, layouts, window rules, startup
    ./noctalia # Noctalia v5 shell: bar, launcher, control center, notifications
    ./qt.nix # Qt Wayland integration and theme settings
    ./mime.nix # Default application associations (MIME types)
    ./cloudflare-warp.nix # WARP tray GUI (matches mySystem.cloudflareWarp)
    ./udiskie.nix # Auto-mount removable media with notifications
    ./themes
  ];
}
