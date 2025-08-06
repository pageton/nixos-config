{ pkgsStable, ... }:

{
  programs = {
    gamemode.enable = true;

    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
  };

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };

  environment.systemPackages = with pkgsStable; [
    mangohud
    protonup
  ];
}
