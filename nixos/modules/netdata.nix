# Netdata real-time system monitoring dashboard (localhost:19999).
# Boot-deferred: starts ~90s after boot to reduce I/O contention.
{
  config,
  lib,
  pkgs,
  pkgsStable,
  ...
}:
{
  services.netdata = {
    enable = true;
    package = pkgs.netdata;

    config = {
      global = {
        "bind to" = "127.0.0.1";
        "default port" = "19999";
        "memory mode" = "dbengine";
        "page cache size" = "64";
        "dbengine multihost disk space" = "512";
      };

      web."enable gzip compression" = "yes";
      cloud."enabled" = "no";
      logs."level" = "error";

      "plugin:ioping"."enabled" = "no";
      "plugin:perf"."enabled" = "no";
      "plugin:freeipmi"."enabled" = "no";
      "plugin:otel"."enabled" = "no";
      "plugin:logs-management"."enabled" = "no";
      "plugin:charts.d"."enabled" = "no";
      "plugin:python.d"."enabled" = "no";
    };

    enableAnalyticsReporting = false;
  };

  users.users.netdata.extraGroups = [
    "systemd-journal"
  ]
  ++ lib.optionals config.virtualisation.docker.enable [ "docker" ];

  systemd.services.netdata = {
    # Defer from multi-user.target to a post-boot timer (reduces boot I/O contention).
    wantedBy = lib.mkForce [ ];
    serviceConfig = {
      MemoryMax = "512M";
      MemoryHigh = "384M";
      Nice = 10;
      IOSchedulingClass = "idle";
      CPUWeight = 20;
      IOWeight = 20;
      ProtectHome = lib.mkForce true;
      ProtectSystem = lib.mkForce "full";
      NoNewPrivileges = lib.mkForce true;
      PrivateTmp = lib.mkForce true;
      ProtectKernelTunables = lib.mkForce true;
      ProtectControlGroups = lib.mkForce true;
      RestrictSUIDSGID = lib.mkForce true;
    };
  };

  systemd.timers."netdata-deferred" = {
    description = "Deferred start for netdata";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "90s";
      RandomizedDelaySec = "20s";
      AccuracySec = "10s";
      Unit = "netdata.service";
    };
  };

  environment.systemPackages = [ pkgsStable.smartmontools ];
}
