# Mullvad VPN configuration.
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Custom module options for Mullvad VPN configuration
  options.mySystem.mullvadVpn = {
    enable = lib.mkEnableOption "Mullvad VPN service";
  };

  # Configuration applied when Mullvad VPN is enabled
  config = lib.mkIf config.mySystem.mullvadVpn.enable {
    # Enable systemd-resolved
    services.resolved.enable = true;

    # Enable Mullvad VPN service
    services.mullvad-vpn = {
      enable = true;
      # GUI package for easy management and desktop integration
      package = pkgs.mullvad-vpn;
    };

    # Add Mullvad VPN to system packages for CLI access
    environment.systemPackages = with pkgs; [mullvad-vpn];
  };
}
