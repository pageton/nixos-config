# Observability — system monitoring, metrics collection, and log aggregation.
{
  imports = [
    ../monitoring.nix # Base monitoring tools and agents
    ../netdata.nix # Netdata real-time system metrics (opt-in via mySystem.netdata)
    ../scrutiny.nix # S.M.A.R.T. disk health monitoring (opt-in via mySystem.scrutiny)
    ../glance # Glance infrastructure dashboard (opt-in via mySystem.glance)
    ../loki.nix # Loki log aggregation for journald
  ];
}
