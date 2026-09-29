# Cloudflare Tunnel — outbound-only connector; no inbound ports required.
#
# Credentials come from the sops secret `cf-tunnel-creds` (a cloudflared
# creds.json blob: AccountTag/TunnelSecret/TunnelID).
# Ingress routes vault.sadiq.lol straight to Vaultwarden on localhost:8222.
#
# Desktop host only (vault-desktop tunnel, created via
# `cloudflared tunnel create vault-desktop`).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Not secret; appears in DNS (<id>.cfargotunnel.com).
  tunnelId = "0011ea12-dadf-44f9-8eba-1d7a3cc44b68";

  credFile = config.sops.secrets.cf-tunnel-creds.path;

  mullvadExclude = "/run/wrappers/bin/mullvad-exclude";

  configFile = pkgs.writeText "cloudflared-config.yml" ''
    tunnel: ${tunnelId}
    credentials-file: ${credFile}

    ingress:
      - hostname: vault.sadiq.lol
        service: http://localhost:8222
      - service: http_status:404
  '';
in
{
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

  systemd.services.cloudflared-tunnel = lib.mkMerge [
    {
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
    }
    (lib.mkIf config.services.mullvad-vpn.enable {
      after = [ "mullvad-daemon.service" ];
      wants = [ "mullvad-daemon.service" ];
      serviceConfig = {
        # mullvad-exclude is a setuid-root wrapper that must elevate to move
        # the process into the mullvad-exclusions cgroup. NoNewPrivileges
        # blocks setuid, so the wrapper fails with EACCES on cgroup.procs.
        # Relax it here; cloudflared itself still runs as the unprivileged
        # cloudflared user after the wrapper execs it.
        NoNewPrivileges = lib.mkForce false;
        ExecStart = lib.mkForce [
          ""
          "${mullvadExclude} ${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate --config ${configFile} run"
        ];
      };
    })
  ];
}
