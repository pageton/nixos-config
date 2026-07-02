# Vaultwarden — self-hosted password manager (single-user, hardened).
# Public reachability is via the Cloudflare Tunnel (modules/cloudflared.nix),
# which routes vault.sadiq.lol directly to this service on localhost:8222.
{ config, lib, ... }:
let
  cfg = config.mySystem.vaultwarden;
in
{
  options.mySystem.vaultwarden = {
    enable = lib.mkEnableOption "Vaultwarden self-hosted password manager";
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      enable = true;
      config = {
        DOMAIN = "https://vault.sadiq.lol";

        # Single-user lockdown
        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = false;
        SHOW_PASSWORD_HINT = false;
        PASSWORD_HINTS_ALLOWED = false;
        ORG_CREATION_USERS = "none";

        # Rate limiting
        LOGIN_RATELIMIT_SECONDS = 60;
        LOGIN_RATELIMIT_MAX_BURST = 10;
        ADMIN_RATELIMIT_SECONDS = 300;
        ADMIN_RATELIMIT_MAX_BURST = 3;

        # Logging
        EXTENDED_LOGGING = true;
        LOG_LEVEL = "info";

        # SSRF protection
        HTTP_REQUEST_BLOCK_NON_GLOBAL_IPS = true;

        # Binding — loopback only; the Cloudflare Tunnel reaches it locally
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        ROCKET_LOG = "critical";

        # Real client IP from the Cloudflare Tunnel (cloudflared sets X-Forwarded-For).
        # Note: differs from the server, which read nginx's X-Real-IP — nginx is not
        # in the path here, and was bypassed by the tunnel there too.
        IP_HEADER = "X-Forwarded-For";
      };
    };
  };
}
