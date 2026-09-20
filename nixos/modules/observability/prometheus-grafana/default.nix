# Prometheus + Alertmanager + Grafana observability stack.
# Adapted from github.com/yzua/nixos-config (nixos-modules/prometheus-grafana).

{
  config,
  constants,
  lib,
  ...
}:

{
  imports = [
    ./_prometheus.nix # modules-check: manual-helper ./_prometheus.nix ./alert-rules.nix — Prometheus + Alertmanager collection and alert routing
    ./_grafana.nix # modules-check: manual-helper Grafana dashboards and visualization
    ./_ntfy-bridge.nix # modules-check: manual-helper Alertmanager → ntfy.sh push notification bridge
    ./_validation.nix # modules-check: manual-helper Observability and ntfy assertions
  ];

  options.mySystem.observability = {
    enable = lib.mkEnableOption "Prometheus + Grafana observability stack";
  };

  options.mySystem.ntfy = {
    enable = lib.mkEnableOption "Alertmanager → ntfy.sh push notification bridge";
    port = lib.mkOption {
      type = lib.types.port;
      default = constants.ports.alertmanager-ntfy;
      description = "Local port for the alertmanager-ntfy bridge.";
    };
  };
}
