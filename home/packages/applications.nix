# General desktop applications including browsers, communication tools,
# productivity software, and theming packages.
{
  pkgs,
  pkgsStable,
  constants,
}:
with pkgs;
with pkgsStable; [
  # === Web Browsers ===
  firefox # Mozilla Firefox web browser

  # === Communication and Collaboration ===
  element-desktop # Matrix protocol client for Element
  remmina # Remote desktop client

  # === Productivity and Knowledge Management ===
  anki-bin # Spaced repetition flashcard system
  obsidian # Knowledge base and note-taking application

  # === AI and Development Tools ===
  pkgs.antigravity-ide-fhs # AI-powered agentic IDE
  # === Terminal Emulators ===
  termius # Modern SSH client with cloud sync

  # === Gaming and Compatibility ===
  (bottles.override {removeWarningPopup = true;}) # Run Windows applications on Linux

  # === Music and Media ===
  pear-desktop # YouTube Music desktop client

  # === Desktop Theming ===
  gnome-themes-extra # Additional GTK themes and base themes

  # === VPN Services ===
  proton-vpn # ProtonVPN graphical client

  # === Windows Compatibility & File Sharing ===
  wineWow64Packages.stagingFull # Wine with WoW64 and staging patches
  samba # SMB/CIFS file sharing

  # === KDE Utilities ===
  kdePackages.ark # KDE archive manager
]
