{pkgs, ...}:
with pkgs; [
  tor-browser # Tor browser
  telegram-desktop # Telegram desktop
  obsidian # Obsidian
  vlc # VLC media player
  vscode # Visual Studio Code
  # Gaming and compatibility tools
  (bottles.override {removeWarningPopup = true;}) # Run Windows applications on Linux
  wineWowPackages.stagingFull
  samba
  zed-editor
  remmina # RDP client
  antigravity
  youtube-music # YouTube Music desktop client
  kdePackages.ark # KDE archive manager
  element-desktop # Matrix client
]
