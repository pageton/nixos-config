# Applications — optional system-level app and service modules (opt-in per host).
{
  imports = [
    ../browser-deps.nix # Browser dependency libraries (Widevine, etc.)
    ../flatpak.nix # Flatpak with Flathub remote (opt-in via mySystem.flatpak)
    ../gaming.nix # Steam, Proton-GE, MangoHud, Lutris (opt-in via mySystem.gaming)
    ../syncthing.nix # Syncthing continuous file sync (opt-in via mySystem.syncthing)
    ../ollama.nix # Ollama local LLM inference server (opt-in via mySystem.ollama)
    ../vaultwarden.nix # Vaultwarden self-hosted password manager (opt-in via mySystem.vaultwarden)
  ];
}
