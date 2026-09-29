# Prometheus + Alertmanager + Grafana observability stack (desktop host only).
# Adapted from github.com/yzua/nixos-config.
#
# Alert flow: Prometheus rules → Alertmanager. The ntfy.sh push bridge was
# never enabled on any host (no ntfy_topic secret exists), so Alertmanager
# currently has a null receiver — alerts are evaluated but not delivered.
# To re-enable delivery, add a webhook receiver here pointing at a bridge.
{
  config,
  constants,
  lib,
  pkgs,
  ...
}:
let
  inherit (constants) localhost ports;

  # Strip http:// prefix for Prometheus scrape targets (needs host:port form)
  mkTarget = url: builtins.substring 7 (builtins.stringLength url - 7) url;
  mkStaticConfig = targets: [ { inherit targets; } ];
  netdataTarget = mkTarget constants.urls.netdata;
  lokiTarget = mkTarget constants.urls.loki;

  mkDatasource =
    {
      name,
      type,
      url,
      uid,
      isDefault ? false,
    }:
    {
      inherit
        name
        type
        url
        uid
        isDefault
        ;
      access = "proxy";
      editable = true;
      orgId = 1;
      jsonData = { };
    };

  datasources = [
    (mkDatasource {
      name = "Prometheus";
      type = "prometheus";
      url = constants.urls.prometheus;
      uid = "prometheus";
      isDefault = true;
    })
    (mkDatasource {
      name = "Loki";
      type = "loki";
      url = "http://${lokiTarget}";
      uid = "loki";
    })
  ];

  dashboardDir = pkgs.runCommand "grafana-dashboards" { } ''
    mkdir -p $out
    cp ${./dashboards/system-overview.json} $out/system-overview.json
    cp ${./dashboards/log-errors.json} $out/log-errors.json
  '';
in
{
  # === Prometheus + Alertmanager ===
  services.prometheus = {
    enable = true;
    port = ports.prometheus;
    listenAddress = localhost;

    globalConfig = {
      scrape_interval = "30s"; # 30s sufficient for personal machine (halves disk/CPU vs 15s default)
      evaluation_interval = "30s";
    };

    scrapeConfigs = [
      {
        job_name = "netdata";
        metrics_path = "/api/v1/allmetrics";
        params.format = [ "prometheus" ];
        static_configs = mkStaticConfig [ netdataTarget ];
      }
      {
        job_name = "loki";
        static_configs = mkStaticConfig [ lokiTarget ];
      }
    ];

    rules = import ./alert-rules.nix;

    alertmanagers = [ { static_configs = mkStaticConfig [ (mkTarget constants.urls.alertmanager) ]; } ];

    extraFlags = [
      "--storage.tsdb.retention.time=30d"
      "--storage.tsdb.retention.size=10GB"
    ];

    alertmanager = {
      enable = true;
      listenAddress = localhost;
      port = ports.alertmanager;
      extraFlags = [ "--cluster.listen-address=" ];

      # Null receiver: alerts are grouped and evaluated but not delivered.
      # See module header about re-enabling a notification bridge.
      configuration = {
        route = {
          receiver = "null";
          group_by = [
            "alertname"
            "severity"
          ];
          group_wait = "30s";
          group_interval = "5m";
          repeat_interval = "4h";
        };
        receivers = [ { name = "null"; } ];
      };
    };
  };

  # === Grafana ===
  sops.secrets.grafana_admin_password = {
    owner = "grafana";
    mode = "0400";
  };

  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = localhost;
        http_port = ports.grafana;
      };

      security = {
        admin_user = "admin";
        admin_password = "$__file{${config.sops.secrets.grafana_admin_password.path}}";
        secret_key = "$__file{${config.sops.secrets.grafana_admin_password.path}}"; # TODO: use a dedicated grafana_secret_key sops secret — reusing admin_password means rotating it breaks encrypted datasources
      };

      "auth.anonymous".enabled = false;
      analytics.reporting_enabled = false;
    };

    provision = {
      datasources.settings = {
        apiVersion = 1;
        deleteDatasources = map (ds: { inherit (ds) name orgId; }) datasources;
        inherit datasources;
      };

      dashboards.settings.providers = [
        {
          name = "default";
          options.path = dashboardDir;
        }
      ];
    };
  };

  systemd.services = {
    prometheus = {
      # Defer from multi-user.target to a post-boot timer (reduces boot I/O contention).
      wantedBy = lib.mkForce [ ];
      serviceConfig = {
        MemoryMax = "512M";
        MemoryHigh = "384M";
        ProtectHome = lib.mkDefault true;
        ProtectSystem = lib.mkDefault "strict";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };

    alertmanager.serviceConfig = {
      MemoryMax = "128M";
      MemoryHigh = "64M";
      ProtectHome = lib.mkDefault true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectKernelTunables = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
    };

    grafana = {
      after = [
        "loki.service"
        "prometheus.service"
      ];
      requires = [ "prometheus.service" ];
      restartTriggers = [ config.sops.secrets.grafana_admin_password.path ];
      # Defer from multi-user.target to a post-boot timer.
      wantedBy = lib.mkForce [ ];
      serviceConfig = {
        MemoryMax = "768M"; # Grafana 13 + unified storage needs more than 256M
        MemoryHigh = "512M";
        ProtectHome = lib.mkDefault true;
        ProtectSystem = lib.mkDefault "strict";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        RestrictSUIDSGID = true;
      };
    };
  };

  systemd.timers = {
    "prometheus-deferred" = {
      description = "Deferred start for prometheus";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "90s";
        RandomizedDelaySec = "20s";
        AccuracySec = "10s";
        Unit = "prometheus.service";
      };
    };

    "grafana-deferred" = {
      description = "Deferred start for grafana";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "90s";
        RandomizedDelaySec = "20s";
        AccuracySec = "10s";
        Unit = "grafana.service";
      };
    };
  };
}
