# Cloudflare Tunnel — outbound-only connector; no inbound ports required.
#
# Ported from the server's modules/cloudflared.nix. Differences:
#   - Credentials come from the sops secret `cf-tunnel-creds` (a cloudflared
#     creds.json blob: AccountTag/TunnelSecret/TunnelID), declared here under
#     mkIf so it only exists on hosts that enable this module.
#   - No credSetupScript / plaintext /etc/cloudflared/secrets.env.
# Ingress routes vault.sadiq.lol straight to Vaultwarden on localhost:8222.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.mySystem.cloudflared;

  credFile = config.sops.secrets.cf-tunnel-creds.path;

  mullvadExclude = "/run/wrappers/bin/mullvad-exclude";

  configFile = pkgs.writeText "cloudflared-config.yml" ''
    tunnel: ${cfg.tunnelId}
    credentials-file: ${credFile}

    ingress:
      - hostname: vault.sadiq.lol
        service: http://localhost:8222
      - service: http_status:404
  '';
in
{
  options.mySystem.cloudflared = {
    enable = lib.mkEnableOption "Cloudflare Tunnel (outbound-only connector)";

    tunnelId = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Cloudflare Tunnel UUID (the <id> in <id>.cfargotunnel.com). Not secret; appears in DNS.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.cf-tunnel-creds = {
      owner = "cloudflared";
      mode = "0400";
    };

    environment.systemPackages = [ pkgs.cloudflared ];

    users.users.cloudflared = {
      isSystemUser = true;
      group = "cloudflared";
      home = "/var/lib/cloudflared";
    };
    users.groups.cloudflared = { };

    systemd.services.cloudflared-tunnel = {
      description = "Cloudflare Tunnel";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate --config ${configFile} run";
        Environment = [ "HOME=/var/lib/cloudflared" ];
        Restart = "on-failure";
        RestartSec = 5;
        User = "cloudflared";
        Group = "cloudflared";
        StateDirectory = "cloudflared";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
      };
    };

    # === Mullvad VPN Bypass ===
    # When Mullvad lockdown-mode is active, all traffic is routed through
    # wg0-mullvad which blocks Cloudflare's edge (port 7844). The
    # mullvad-exclude wrapper unsets the fwmark so cloudflared's outbound
    # connections bypass the VPN tunnel and reach Cloudflare directly.
    systemd.services.cloudflared-tunnel = lib.mkIf config.mySystem.mullvadVpn.enable {
      after = [ "mullvad-daemon.service" ];
      wants = [ "mullvad-daemon.service" ];
      serviceConfig.ExecStart = lib.mkForce [
        ""
        "${mullvadExclude} ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate --config ${configFile} run"
      ];
    };
  };
}
