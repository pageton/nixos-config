# Home-Manager base modules — core identity, session, desktop entries, and activation.
{ ... }:
{
  imports = [
    ./user.nix # Username, homeDirectory, stateVersion, packages, fonts
    ./session.nix # Session variables (Qt/GTK/Electron Wayland), telemetry opt-out
    ./desktop-entries.nix # Custom .desktop files for firejail-wrapped apps
    ./gtk-dconf.nix # Dark theme preference, privacy settings (no recent files)
    ./activation.nix # Custom HM activation script (nix profile management)
  ];
}
