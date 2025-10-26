{ pkgs, pkgsStable, ... }:

(with pkgsStable; [ kdePackages.xwaylandvideobridge ])
++ (with pkgs; [
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  wl-clipboard
  clipman
  qt5.qtwayland
  qt6.qtwayland
  libsForQt5.qt5ct
  qt6ct
  hyprshot
  hyprpicker
  swappy
  imv
  wf-recorder
  wlr-randr
  brightnessctl
  gnome-themes-extra
  libva
  dconf
  wayland-utils
  wayland-protocols
  glib
  direnv
  meson
  libnotify
  bemoji
  playerctl
  grimblast
  wtype
  cliphist
  swayosd
])
