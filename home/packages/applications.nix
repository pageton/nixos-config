{ pkgs, ... }:

with pkgs;
[
  tor-browser # Tor browser
  brave # Brave browser
  telegram-desktop # Telegram desktop
  obs-studio # OBS Studio
  # obsidian # Obsidian
  vlc # VLC media player
  vesktop # Discord desktop client
  vscode # Visual Studio Code
  chromium # Chromium web browser
  # Gaming and compatibility tools
  (bottles.override { removeWarningPopup = true; }) # Run Windows applications on Linux
  rustdesk # Remote desktop software
  anydesk # Remote desktop software
  wineWowPackages.stagingFull
  winetricks
  samba
  kdePackages.dolphin # KDE file manager
]
