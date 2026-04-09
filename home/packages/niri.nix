# Niri compositor and Wayland utilities including clipboard management,
# screenshot tools, and desktop integration.
{ pkgsStable, ... }:
with pkgsStable;
[
  # === Clipboard Management ===
  cliphist # Clipboard history manager
  wl-clip-persist # Keep clipboard content after source closes
  wl-clipboard # Wayland clipboard utilities (wl-copy, wl-paste)
  wtype # Wayland keyboard and mouse input simulation

  # === Desktop Integration ===
  libnotify # Desktop notification library
  # playerctl is provided by services.playerctld (home/system/niri/default.nix)

  # === Screenshot and Capture ===
  grim # Wayland screenshot tool (used by swappy pipeline)
  slurp # Region selector for grim

  # === Wayland Utilities ===
  bemoji # Emoji picker for Wayland
  brightnessctl # Screen brightness control
  showmethekey # Show pressed keys on screen
]
