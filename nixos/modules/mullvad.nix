# Mullvad VPN configuration.
{pkgs, ...}: {
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
}
