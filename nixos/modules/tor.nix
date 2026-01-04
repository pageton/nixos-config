# Tor service configuration for privacy and anonymity.
{
  config,
  lib,
  ...
}: {
  # Custom module options for Tor configuration
  options.mySystem.tor = {
    enable = lib.mkEnableOption "Tor service for privacy and anonymity";
  };

  # Configuration applied when Tor is enabled
  config = lib.mkIf config.mySystem.tor.enable {
    services.tor = {
      enable = true; # Enable Tor daemon
      torsocks.enable = true; # Enable torsocks for transparent Tor routing
      client.enable = true; # Enable Tor client functionality
    };
  };
}
