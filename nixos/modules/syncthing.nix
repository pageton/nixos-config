# Syncthing decentralized file synchronization.
{ user, ... }:
{
  services.syncthing = {
    enable = true;
    inherit user;
    dataDir = "/home/${user}/Sync";
    configDir = "/home/${user}/.config/syncthing";
    openDefaultPorts = true;

    settings.options = {
      urAccepted = -1;
    };
  };
}
