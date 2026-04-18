# Desktop environment — Niri Wayland compositor, display manager, and portals.
{
  imports = [
    ../niri.nix # Niri scrollable-tiling compositor + xwayland-satellite
    ../sddm.nix # SDDM display manager (Wayland, themed)
    ../xserver.nix # X11 explicitly disabled (Wayland-only)
    ../xdg-desktop-portal.nix # XDG portals: FileChooser (GTK), ScreenCast/Screenshot (GNOME)
  ];
}
