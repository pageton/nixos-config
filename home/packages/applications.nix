{ pkgs, ... }:

with pkgs;
[
  tor-browser # Tor browser
  telegram-desktop # Telegram desktop
  obsidian # Obsidian
  vlc # VLC media player
  vesktop # Discord desktop client
  vscode # Visual Studio Code
  # Gaming and compatibility tools
  (bottles.override { removeWarningPopup = true; }) # Run Windows applications on Linux
  rustdesk # Remote desktop software
  anydesk # Remote desktop software
  wineWowPackages.stagingFull
  samba
  kdePackages.dolphin # KDE file manager
  materialgram
]
