# Loopback-only HTTP CONNECT forward for ZCode's z.ai traffic. Node's
# Happy-Eyeballs caps each connect attempt at 250ms; the only api.z.ai IPv4
# edges (8.217.x Aliyun GA) need ~270-920ms from this line, so ZCode's undici
# fetches die with ETIMEDOUT whenever the Mullvad tunnel (which provides fast
# IPv6) is down. The forwarder accepts CONNECT on loopback (instant for Node)
# and dials the upstream itself without Node's attempt budget. ZCode reaches
# it through the supported path: AppSettings.httpProxy in ~/.zcode/v2/setting.json.
{ lib, pkgs, ... }:
let
  port = 18901;
  configFile = pkgs.writeText "tinyproxy-zai-forward.conf" ''
    Port ${toString port}
    Listen 127.0.0.1
    Allow 127.0.0.1
    Timeout 1800
    LogLevel Error
    ConnectPort 443
  '';
in
{
  home.packages = [ pkgs.tinyproxy ];

  systemd.user.services.zai-forward = {
    Unit = {
      Description = "Loopback CONNECT forward for ZCode z.ai traffic";
      After = [ "network-online.target" ];
      # ZCode depends on this fail-closed; never let a transient failure
      # (e.g. port 18901 briefly held by a manual instance) leave the unit
      # permanently dead behind the start limit. RestartSec=1 floors the rate.
      StartLimitIntervalSec = 0;
    };
    Service = {
      Type = "exec";
      ExecStart = "${lib.getExe pkgs.tinyproxy} -d -c ${configFile}";
      # ZCode's explicit proxy is fail-closed: if the forwarder is gone, all
      # proxied ZCode traffic fails until it returns. Recover immediately.
      Restart = "always";
      RestartSec = 1;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = "tmpfs";
      ProtectSystem = "strict";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
