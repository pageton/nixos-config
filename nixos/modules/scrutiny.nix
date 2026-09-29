# Scrutiny SMART disk health monitoring (localhost:8010).
# Boot-deferred: scrutiny + influxdb2 start ~90s after boot.
{
  lib,
  constants,
  pkgs,
  ...
}:
{
  services = {
    scrutiny = {
      enable = true;
      openFirewall = false;

      settings = {
        web.listen = {
          host = "127.0.0.1";
          port = constants.ports.scrutiny;
        };
        log.level = "INFO";
      };

      collector = {
        enable = true;
        schedule = "daily";
      };
    };

    # Bind InfluxDB backend to localhost
    influxdb2.settings.http-bind-address = "127.0.0.1:8086";
  };

  systemd = {
    services =
      let
        waitScript = pkgs.writeShellScript "wait-for-scrutiny" ''
          for i in $(seq 1 30); do
            ${pkgs.curl}/bin/curl -sf ${constants.urls.scrutiny}/api/summary >/dev/null 2>&1 && exit 0
            sleep 2
          done
          echo "Scrutiny API not ready after 60s"
          exit 1
        '';
      in
      {
        # Wait for Scrutiny web API before collector runs (prevents boot race condition)
        scrutiny-collector.serviceConfig = {
          ExecStartPre = [ "${waitScript}" ];
          PrivateTmp = lib.mkForce true;
          ProtectHome = lib.mkForce true;
          NoNewPrivileges = lib.mkForce true;
          ProtectKernelTunables = lib.mkForce true;
          ProtectControlGroups = lib.mkForce true;
          RestrictSUIDSGID = lib.mkForce true;
          # Collector needs access to /dev for SMART data — no ProtectSystem=strict
        };

        # Retention: purge InfluxDB WAL/data older than 1 year (Scrutiny grows ~1MB/day)
        scrutiny-retention-cleanup = {
          description = "Clean old Scrutiny InfluxDB data";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.findutils}/bin/find /var/lib/influxdb2 -type f -name '*.tsm' -mtime +365 -delete";
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ProtectKernelTunables = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            ReadWritePaths = [ "/var/lib/influxdb2" ];
          };
        };

        # Systemd hardening + resource limits
        scrutiny = {
          # Defer from multi-user.target to a post-boot timer.
          wantedBy = lib.mkForce [ ];
          serviceConfig = {
            MemoryMax = "128M";
            MemoryHigh = "96M";
            Nice = 10;
            IOSchedulingClass = "idle";
            CPUWeight = 20;
            IOWeight = 20;
            PrivateTmp = lib.mkForce true;
            ProtectSystem = lib.mkForce "strict";
            ProtectHome = lib.mkForce true;
            NoNewPrivileges = lib.mkForce true;
            ProtectKernelTunables = lib.mkForce true;
            ProtectControlGroups = lib.mkForce true;
            RestrictSUIDSGID = lib.mkForce true;
            ReadWritePaths = [ "/var/lib/scrutiny" ];
          };
        };

        influxdb2 = {
          # Defer alongside scrutiny.
          wantedBy = lib.mkForce [ ];
          serviceConfig = {
            MemoryMax = "256M";
            MemoryHigh = "192M";
            Nice = 10;
            IOSchedulingClass = "idle";
            CPUWeight = 20;
            IOWeight = 20;
          };
        };
      };

    timers = {
      "scrutiny-deferred" = {
        description = "Deferred start for scrutiny";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "90s";
          RandomizedDelaySec = "20s";
          AccuracySec = "10s";
          Unit = "scrutiny.service";
        };
      };

      "influxdb2-deferred" = {
        description = "Deferred start for influxdb2";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "90s";
          RandomizedDelaySec = "20s";
          AccuracySec = "10s";
          Unit = "influxdb2.service";
        };
      };

      scrutiny-retention-cleanup = {
        description = "Monthly Scrutiny InfluxDB data cleanup";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "monthly";
          Persistent = true;
          RandomizedDelaySec = "1h";
        };
      };
    };
  };
}
