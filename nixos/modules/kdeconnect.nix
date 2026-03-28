# KDE Connect for phone-desktop integration.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.mySystem.kdeconnect = {
    enable = lib.mkEnableOption "KDE Connect phone-desktop integration";
  };

  config = lib.mkIf config.mySystem.kdeconnect.enable {
    environment.systemPackages = [ pkgs.kdePackages.kdeconnect-kde ];
    programs.kdeconnect.enable = true;
  };
}
