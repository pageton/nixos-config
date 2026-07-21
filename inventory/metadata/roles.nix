# Role definitions — committed to Git (public-safe).
#
# Maps role keys (used in servers.nix `roles` lists) to descriptions.
# Roles are public metadata; they describe what a server does, not where it is.
{
  web = "Web server (nginx/caddy)";
  database = "Database server (postgresql)";
  monitoring = "Monitoring stack (prometheus/grafana)";
  ci-runner = "CI runner (ephemeral build agent)";
  build-agent = "Build agent (ephemeral compilation)";
  proxy = "Reverse proxy / load balancer";
  storage = "Object/block storage server";
  vpn = "VPN endpoint (wireguard/tailscale)";
}
