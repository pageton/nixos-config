# Defer non-critical services from blocking boot (reduces I/O contention by ~10-15s).
{
  config,
  lib,
  ...
}:

let
  cfg = config.mySystem;

  # Services to defer from multi-user.target to a post-boot timer.
  # These are monitoring/observability services that compete for I/O during boot
  # but don't block the login prompt. Deferring them reduces boot contention.
  deferredServices =
    lib.optionals cfg.netdata.enable [ "netdata" ]
    ++ lib.optionals cfg.loki.enable [
      "loki"
      "promtail"
    ]
    ++ lib.optionals cfg.scrutiny.enable [
      "scrutiny"
      "influxdb2"
    ];

  # Generate wantedBy overrides: remove each service from multi-user.target
  serviceOverrides = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = {
        wantedBy = lib.mkForce [ ];
        serviceConfig = {
          Nice = lib.mkForce 10;
          IOSchedulingClass = lib.mkForce "idle";
          CPUWeight = lib.mkForce 20;
          IOWeight = lib.mkForce 20;
        };
      };
    }) deferredServices
  );

  # Generate timers: start each deferred service 90s after boot
  timerEntries = builtins.listToAttrs (
    map (name: {
      name = "${name}-deferred";
      value = {
        description = "Deferred start for ${name}";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "90s";
          RandomizedDelaySec = "20s";
          AccuracySec = "10s";
          Unit = "${name}.service";
        };
      };
    }) deferredServices
  );
in
{
  systemd.services = serviceOverrides;
  systemd.timers = timerEntries;
}
