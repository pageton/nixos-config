# Prometheus + Grafana Stack

Observability stack module for Prometheus, Alertmanager, and Grafana on localhost.
Adapted from `github.com/yzua/nixos-config` (`nixos-modules/prometheus-grafana`).
Enabled through `mySystem.observability.enable` and integrated with Netdata/Loki and the ntfy bridge alerts.

## Structure

| File              | Purpose                                                                                              |
| ----------------- | ---------------------------------------------------------------------------------------------------- |
| `default.nix`     | Options (`mySystem.observability`, `mySystem.ntfy`) and imports of the config helpers                |
| `_prometheus.nix` | Prometheus and Alertmanager configuration (scrape targets, alert routing)                            |
| `_grafana.nix`    | Grafana server settings, provisioning, and datasource wiring                                         |
| `_helpers.nix`    | Shared helper functions (not a module, imported by other files)                                      |
| `_ntfy-bridge.nix`| Alertmanager → ntfy.sh push bridge (opt-in via `mySystem.ntfy.enable`)                               |
| `_validation.nix` | Assertions: loki required, localhost bindings, sops secrets present                                  |
| `alert-rules.nix` | Alert rule groups (system, disk, services, network)                                                  |
| `dashboards/`     | Provisioned Grafana dashboard JSON files                                                             |

## Conventions

- Keep services bound to loopback (`constants.localhost`) unless explicitly changing security posture.
- Ports come from `shared/constants.nix` (`ports.prometheus`, `ports.grafana`, `ports.alertmanager`, `ports.loki`, `ports.netdata`, `ports.alertmanager-ntfy`) — never hardcode.
- Maintain dashboard provisioning via the `pkgs.runCommand` copy workflow in `_grafana.nix`.
- Keep alert routing centralized in the Alertmanager config (webhook to the ntfy bridge).
- Update alert thresholds in `alert-rules.nix`; keep labels and severity explicit.
- Grafana admin password is sourced from the `grafana_admin_password` sops secret (`just secrets-add grafana_admin_password`).
- Local adaptations vs upstream: `systemdHelpers` imported directly from `../helpers/_systemd-helpers.nix`, no `mySystem.systemReport`, `mySystem.ntfy` options defined here.

## Dependencies

- `mySystem.observability.enable = true` toggles this stack; `mySystem.loki.enable` is asserted as required.
- Expects Loki (`127.0.0.1:3100`) and Netdata (`127.0.0.1:19999`) scrape targets when enabled.
- ntfy bridge additionally needs `mySystem.ntfy.enable = true` and the `ntfy_topic` sops secret.

## Validation

```bash
just modules
just lint
just format
just check
```
