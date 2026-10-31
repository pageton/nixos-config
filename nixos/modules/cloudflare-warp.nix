# Cloudflare WARP (one.one.one.one) client — warp-svc daemon + warp-cli.
#
# The GUI (warp-taskbar tray applet) is started per-user via Home-Manager
# (home/cloudflare-warp) on hosts that import this module.
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
{ lib, pkgs, ... }: {
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

  # Keep WARP in local SOCKS proxy mode ("WarpProxy", listener
  # 127.0.0.1:40000). Proxy mode establishes the tunnel for the SOCKS
  # listener only — no system routes, no DNS takeover — so nothing on the
  # host changes unless an app explicitly uses the proxy (the zcode
  # wrapper from home/ai/default.nix does). Consumer warp-cli defaults to
  # full-tunnel Warp mode on connect, which breaks geo-fenced local
  # services; this oneshot re-asserts proxy mode at boot/daemon restart
  # and reconnects. All commands are idempotent.
  systemd.services.warp-proxy-ensure = {
    description = "Ensure Cloudflare WARP stays in SOCKS proxy mode";
    after = [ "cloudflare-warp.service" ];
    wants = [ "cloudflare-warp.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.cloudflare-warp ];
    script = ''
      # Wait for the daemon socket (it can take a few seconds after boot).
      for _ in $(seq 1 30); do
        warp-cli status >/dev/null 2>&1 && break
        sleep 2
      done
      # Anonymous consumer registration (persisted in /var/lib once made).
      warp-cli registration show >/dev/null 2>&1 \
        || warp-cli registration new >/dev/null 2>&1 \
        || true
      warp-cli mode proxy || true
      warp-cli connect || true
    '';
  };
}
