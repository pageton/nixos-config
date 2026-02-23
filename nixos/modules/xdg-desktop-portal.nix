# XDG Desktop Portal Configuration
# This module provides proper configuration for xdg-desktop-portal services
# optimized for niri Wayland compositor (uses GNOME portal for ScreenCast)
{
  pkgs,
  ...
}: {
  # Install xdg-desktop-portal and related packages
  environment.systemPackages = with pkgs; [
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome # GNOME portal for ScreenCast/Screenshot (niri-compatible)
    xdg-utils
    thunar # Thunar file manager
    tumbler # Thumbnail service for Thunar
  ];

  # Set default portal implementations for Wayland/niri
  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    GTK_USE_PORTAL = "1";
  };

  # Configure portal implementations for niri
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome # niri implements GNOME ScreenCast portal protocol
    ];
    config = {
      common = {
        default = [
          "gtk"
          "gnome"
        ];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
        "org.freedesktop.impl.portal.Screenshot" = ["gnome"];
        "org.freedesktop.impl.portal.ScreenCast" = ["gnome"];
      };
    };
  };
}
