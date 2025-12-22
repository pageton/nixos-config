# XDG Desktop Portal Configuration
# This module provides proper configuration for xdg-desktop-portal services
# optimized for Hyprland Wayland environment
{
  pkgs,
  lib,
  hostname,
  ...
}:
lib.mkIf (hostname != "server") {
  # Install xdg-desktop-portal and related packages
  environment.systemPackages = with pkgs; [
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland # Hyprland-specific portal
    xdg-utils
  ];

  # Set default portal implementations for Wayland/Hyprland
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    GTK_USE_PORTAL = "1";
  };

  # Configure portal implementations for Hyprland
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland # Use Hyprland portal instead of wlr
    ];
    config = {
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        "org.freedesktop.impl.portal.Screenshot" = ["hyprland"];
        "org.freedesktop.impl.portal.ScreenCast" = ["hyprland"];
      };
    };
  };
}
