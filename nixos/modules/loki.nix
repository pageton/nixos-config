# Loki log aggregation with Grafana Alloy (replaces Promtail, removed in 26.05).
# Desktop host only. Boot-deferred: loki + alloy start ~90s after boot.
{
  lib,
  pkgs,
  ...
}:
{
  services.loki = {
    enable = true;

    configuration = {
      auth_enabled = false; # Single-tenant, localhost only

      server = {
        http_listen_port = 3100;
        http_listen_address = "127.0.0.1";
        grpc_listen_port = 9096;
        grpc_listen_address = "127.0.0.1";
      };

      common = {
        path_prefix = "/var/lib/loki";
        storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
        replication_factor = 1;
        ring = {
          instance_addr = "127.0.0.1";
          kvstore.store = "inmemory";
        };
        instance_interface_names = [ ]; # Skip interface detection (fails on NixOS)
        instance_addr = "127.0.0.1";
      };

      schema_config = {
        configs = [
          {
            from = "2024-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }
        ];
      };

      limits_config = {
        retention_period = "720h"; # 30 days
        ingestion_rate_mb = 4;
        ingestion_burst_size_mb = 6;
      };

      compactor = {
        working_directory = "/var/lib/loki/compactor";
        retention_enabled = true;
        retention_delete_delay = "2h";
        delete_request_store = "filesystem";
      };
    };
  };

  # Grafana Alloy ships journald logs to Loki (successor to Promtail).
  services.alloy = {
    enable = true;

    configPath = pkgs.writeText "alloy-config.alloy" ''
      loki.relabel "journal" {
        forward_to = []

        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }

        rule {
          source_labels = ["__journal__hostname"]
          target_label  = "hostname"
        }

        rule {
          source_labels = ["__journal_priority_keyword"]
          target_label  = "level"
        }
      }

      loki.source.journal "read" {
        forward_to    = [loki.write.local.receiver]
        relabel_rules = loki.relabel.journal.rules
        max_age       = "12h"
        labels        = {
          job = "systemd-journal",
        }
      }

      loki.write "local" {
        endpoint {
          url = "http://127.0.0.1:3100/loki/api/v1/push"
        }
      }
    '';
  };

  # Defer from multi-user.target to post-boot timers.
  systemd.services = {
    loki = {
      wantedBy = lib.mkForce [ ];
      serviceConfig = {
        MemoryMax = "256M";
        MemoryHigh = "192M";
        Nice = 10;
        IOSchedulingClass = "idle";
        CPUWeight = 20;
        IOWeight = 20;
        PrivateTmp = lib.mkForce true;
        ProtectSystem = lib.mkForce "strict"; # Upstream sets "full"; we want stricter
        ProtectHome = lib.mkForce true;
        NoNewPrivileges = lib.mkForce true;
        ProtectKernelTunables = lib.mkForce true;
        ProtectControlGroups = lib.mkForce true;
        RestrictSUIDSGID = lib.mkForce true;
        ReadWritePaths = [ "/var/lib/loki" ];
      };
    };

    alloy = {
      wantedBy = lib.mkForce [ ];
      serviceConfig = {
        # Alloy (DynamicUser in 26.05) needs journal access via supplementary group
        SupplementaryGroups = [ "systemd-journal" ];
        MemoryMax = "128M";
        MemoryHigh = "64M";
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
        ReadWritePaths = [
          "/var/lib/alloy"
          "/var/log/journal"
        ];
      };
    };
  };

  systemd.timers = {
    "loki-deferred" = {
      description = "Deferred start for loki";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "90s";
        RandomizedDelaySec = "20s";
        AccuracySec = "10s";
        Unit = "loki.service";
      };
    };

    "alloy-deferred" = {
      description = "Deferred start for alloy";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "90s";
        RandomizedDelaySec = "20s";
        AccuracySec = "10s";
        Unit = "alloy.service";
      };
    };
  };
}
