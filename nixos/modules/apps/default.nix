# Applications — optional system-level app and service modules (opt-in per host).
{
  imports = [
    ../browser-deps.nix # Browser dependency libraries (Widevine, etc.)
    ../flatpak.nix # Flatpak with Flathub remote (opt-in via mySystem.flatpak)
    ../gaming.nix # Steam, Proton-GE, MangoHud, Lutris (opt-in via mySystem.gaming)
    ../syncthing.nix # Syncthing continuous file sync (opt-in via mySystem.syncthing)
  ];
}
