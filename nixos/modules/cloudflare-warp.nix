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
#   which knows nothing about warp's pseudo-domains. The post-connect check
#   (resolves connectivity-check.warp-svc.) therefore loops at "Performing
#   connectivity checks" even though the tunnel carries traffic fine. Skip
#   it permanently: `warp-cli debug connectivity-check disable` (runtime) or
#   the MDM key seeded below (declarative). Verify the tunnel live via
#   https://www.cloudflare.com/cdn-cgi/trace, expecting `warp=on`.
# - The GUI "Mode" must stay "Traffic and DNS". The "1.1.1.1" entry is
#   DNS-over-TLS only: it shows "Connected" but creates NO tunnel.
#
# Coexistence with Mullvad lockdown mode: Mullvad's kill switch only allows
# traffic through its tunnel, so WARP establishes its tunnel *inside* Mullvad
# (nested WireGuard) and only while Mullvad is connected. When Mullvad drops,
# lockdown blocks WARP too. While WARP is connected it rewrites
# /etc/resolv.conf to Cloudflare DNS (1.1.1.1); when it disconnects cleanly
# the file is restored.
{
  config,
  lib,
  pkgs,
  ...
}:
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

    # Seed the MDM file with disable_connectivity_checks on first start (see
    # gotcha above). Written once; manual edits under /var/lib are preserved.
    systemd.services.cloudflare-warp.serviceConfig.ExecStartPre = [
      (lib.getExe (
        pkgs.writeShellScriptBin "cloudflare-warp-mdm-seed" ''
          if [ ! -f /var/lib/cloudflare-warp/mdm.xml ]; then
            install -D -m 0644 ${pkgs.writeText "cloudflare-warp-mdm.xml" ''
              <dict>
                <key>disable_connectivity_checks</key>
                <true/>
              </dict>
            ''} /var/lib/cloudflare-warp/mdm.xml
          fi
        ''
      ))
    ];
  };
}
