# Hyprland window manager and Wayland utilities including screenshot tools,
# clipboard management, and desktop integration.
{
  pkgs,
  pkgsStable,
}:
with pkgs;
with pkgsStable; [
  # === Hyprland-Specific Utilities ===
  bemoji # Emoji picker for Wayland
  brightnessctl # Screen brightness control
  hyprpicker # Color picker for Hyprland

  # === Screenshot and Capture Utilities ===
  grim # Screenshot utility for Wayland
  slurp # Region selection utility for Wayland
  wf-recorder # Wayland screen recorder

  # === Clipboard Management ===
  cliphist # Clipboard history manager
  wl-clipboard # Wayland clipboard utilities
  wtype # Wayland keyboard and mouse input simulation

  # === Desktop Integration ===
  # Note: xdg-desktop-portal-hyprland and xdg-desktop-portal-gtk are in nixos/modules/xdg-desktop-portal.nix
  libnotify # Desktop notification library
  playerctl # Media player control utility

  # === Hyprland Plugins ===
  hyprlandPlugins.hyprbars # Title bar for floating windows

  # === System Utilities ===
  swayosd # Wayland status bar
]
