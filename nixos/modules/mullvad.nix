# Mullvad VPN configuration.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.mySystem.mullvadVpn = {
    enable = lib.mkEnableOption "Mullvad VPN service";
  };

  config = lib.mkIf config.mySystem.mullvadVpn.enable {
    services.mullvad-vpn = {
      enable = true;
      package = pkgs.mullvad-vpn;
    };

    environment.systemPackages = [ pkgs.mullvad-vpn ];
  };
}
