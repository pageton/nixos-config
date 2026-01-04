# Bitwarden (or vaultwarden) is a self-hosted password manager.
{
  config,
  lib,
  ...
}: let
  cfg = config.mySystem.bitwarden;
  domain = "vault.sadiq.lol";
in {
  options.mySystem.bitwarden = {
    enable = lib.mkEnableOption "Vaultwarden password manager";
  };

  config = lib.mkIf cfg.enable {
    services = {
      vaultwarden = {
        enable = true;
        config = {
          DOMAIN = "https://" + domain;
          SIGNUPS_ALLOWED = true;
          ROCKET_ADDRESS = "127.0.0.1";
          ROCKET_PORT = 8222;
          ROCKET_LOG = "critical";
        };
      };
    };
  };
}
