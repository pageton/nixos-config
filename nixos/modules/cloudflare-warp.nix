# Cloudflare WARP (one.one.one.one) client — warp-svc daemon + warp-cli.
#
# The GUI (warp-taskbar tray applet) is started per-user via Home-Manager
# (home/desktop/cloudflare-warp) on hosts that enable this module.
#
# Gotchas (client 2026.7.1343.0 on NixOS):
# - The client ships with the MASQUE protocol; on this host its
#   inside-tunnel DNS check always fails (FailedConnectivityCheck
#   (DNSLookupFailed)) and the GUI sticks at "Performing connectivity
#   checks" (56-81%) forever. Force the WireGuard (UDP) transport once —
#   it is stored in /var/lib/cloudflare-warp and survives reboots:
#     warp-cli tunnel protocol set WireGuard
# - warp-svc cannot parse NixOS's systemd version slug ("261.2" lacks the
#   "-<distro>" suffix it expects), so it falls back to file-based DNS and
#   rewrites /etc/resolv.conf to its local proxy (127.0.2.2/.3). Because
#   nsswitch routes getaddrinfo through systemd-resolved
#   (hosts: … resolve [!UNAVAIL=return] … dns), the daemon's post-connect
#   check can still loop in "Performing connectivity checks" even though
#   the tunnel carries traffic fine; disconnect/connect again if stuck.
# - The GUI "Mode" must stay "Traffic and DNS". The "1.1.1.1" entry is
#   DNS-over-TLS only: it shows "Connected" but creates NO tunnel.
#
# Coexistence with Mullvad lockdown mode: Mullvad's kill switch only allows
# traffic through its tunnel, so WARP establishes its tunnel *inside* Mullvad
# (nested WireGuard) and only while Mullvad is connected. When Mullvad drops,
# lockdown blocks WARP too. While WARP is connected it rewrites
# /etc/resolv.conf to Cloudflare DNS (1.1.1.1); when it disconnects cleanly
# the file is restored.
{ config, lib, ... }:
let
  cfg = config.mySystem.cloudflareWarp;
in
{
  options.mySystem.cloudflareWarp = {
    enable = lib.mkEnableOption "Cloudflare WARP client (warp-svc daemon, warp-cli, 1.1.1.1 DNS)";
  };

  config = lib.mkIf cfg.enable {
    # Upstream module: warp-svc system daemon (root, CAP_NET_ADMIN, nftables),
    # cloudflare-warp package in systemPackages, /var/lib/cloudflare-warp state.
    services.cloudflare-warp = {
      enable = true;

      # WARP is a client-initiated outbound tunnel; replies match the outbound
      # flow via the stateful firewall. Keep the zero-inbound-ports posture
      # from security.nix instead of opening UDP 2408 (and on Mullvad lockdown
      # hosts unsolicited inbound is blocked regardless).
      openFirewall = false;
    };
  };
}
