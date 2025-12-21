# Tailscale is a VPN service that works on top of WireGuard.
# It allows me to access my servers and devices from anywhere.
{pkgsStable, ...}: {
  home.packages = with pkgsStable; [tailscale tailscale-systray];
}
