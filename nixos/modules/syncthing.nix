# Syncthing decentralized file synchronization.
{
  config,
  lib,
  user,
  ...
}:
{
  options.mySystem.syncthing = {
    enable = lib.mkEnableOption "Syncthing local file synchronization";
  };

  config = lib.mkIf config.mySystem.syncthing.enable {
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
  };
}
