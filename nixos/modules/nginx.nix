# Nginx configuration.
{
  config,
  lib,
  ...
}: let
  cfg = config.mySystem.nginx;
in {
  options.mySystem.nginx = {
    enable = lib.mkEnableOption "Nginx web server with reverse proxy";
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts = {
        "default" = {
          default = true;
          locations."/" = {return = 404;};
        };
        "sadiq.lol" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
          };
        };
        "vault.sadiq.lol" = {
          locations."/" = {
            proxyPass = "http://127.0.0.1:8222";
          };
        };
      };
    };
    networking.firewall = {
      allowedTCPPorts = [80 443];
      allowedUDPPorts = [80 443];
    };
  };
}
