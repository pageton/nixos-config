# DNSCrypt-Proxy configuration for encrypted DNS.
# Provides DNS over HTTPS/TLS to prevent DNS leaks and improve privacy.
{
  config,
  lib,
  ...
}: {
  # Custom module options for DNSCrypt-Proxy configuration
  options.mySystem.dnscryptProxy = {
    enable = lib.mkEnableOption "DNSCrypt-Proxy for encrypted DNS and DNS leak prevention";
  };

  # Configuration applied when DNSCrypt-Proxy is enabled
  config = lib.mkIf config.mySystem.dnscryptProxy.enable {
    # Enable DNSCrypt-Proxy service
    services.dnscrypt-proxy = {
      enable = true;

      settings = {
        # Listen on localhost for DNS queries
        listen_addresses = ["127.0.0.1:53"];

        # Server names to use
        server_names = [
          "cloudflare"
          "cloudflare-security"
        ];

        # Fallback resolvers
        fallback_resolvers = [
          "9.9.9.9:53"
          "8.8.8.8:53"
        ];

        # Cache settings
        cache = true;
        cache_size = 256;

        # Logging
        log_level = 2;
        log_file = "/var/log/dnscrypt-proxy/dnscrypt-proxy.log";
      };
    };
  };
}
