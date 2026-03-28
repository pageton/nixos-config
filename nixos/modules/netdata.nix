{
  config,
  lib,
  pkgsStable,
  ...
}:

{
  options.mySystem.netdata = {
    enable = lib.mkEnableOption "Netdata real-time system monitoring dashboard";
  };

  config = lib.mkIf config.mySystem.netdata.enable {
    services.netdata = {
      enable = true;
      package = pkgsStable.netdataCloud;

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

    systemd.services.netdata.serviceConfig = {
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

    environment.systemPackages = [ pkgsStable.smartmontools ];
  };
}
