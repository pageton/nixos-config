# General desktop applications including browsers, communication tools,
# productivity software, and theming packages.
{
  pkgs,
  pkgsStable,
}:
with pkgs;
with pkgsStable; [
  # === Web Browsers ===
  firefox # Mozilla Firefox web browser

  # === Communication and Collaboration ===
  element-desktop # Matrix protocol client for Element
  telegram-desktop # Telegram messaging application
  ayugram-desktop
  remmina # Remote desktop client

  # === Productivity and Knowledge Management ===
  anki-bin # Spaced repetition flashcard system
  obsidian # Knowledge base and note-taking application
  libreoffice-qt6-fresh # Full office suite with Qt6 interface

  # === AI and Development Tools ===
  antigravity-fhs # AI-powered agentic IDE

  # === Gaming and Compatibility ===
  (bottles.override {removeWarningPopup = true;}) # Run Windows applications on Linux

  # === Music and Media ===
  youtube-music # YouTube Music desktop client

  # === Desktop Theming ===
  gnome-themes-extra # Additional GTK themes and base themes

  # === VPN Services ===
  protonvpn-gui # ProtonVPN graphical client

  # === Windows Compatibility & File Sharing ===
  wineWowPackages.stagingFull # Wine with WoW64 and staging patches
  samba # SMB/CIFS file sharing

  # === KDE Utilities ===
  kdePackages.ark # KDE archive manager
]
