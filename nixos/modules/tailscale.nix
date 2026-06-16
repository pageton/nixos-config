# Tailscale private mesh networking for remote access from trusted devices.

{
  config,
  lib,
  pkgs,
  constants,
  ...
}:

let
  cfg = config.mySystem.tailscale;
  mullvadExclude = "/run/wrappers/bin/mullvad-exclude";
  tsDomain = "tail12fed2.ts.net";
in
{
  options.mySystem.tailscale = {
    enable = lib.mkEnableOption "Tailscale private mesh networking";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      extraSetFlags = [
        "--accept-dns=false"
        "--accept-routes=false"
        "--exit-node="
        "--netfilter-mode=nodivert"
      ];
      openFirewall = true;
      useRoutingFeatures = "client";
    };

    environment.systemPackages = [ pkgs.tailscale ];

    systemd.services.tailscaled = lib.mkIf config.mySystem.mullvadVpn.enable {
      wants = [ "mullvad-daemon.service" ];
      after = [ "mullvad-daemon.service" ];
      serviceConfig.ExecStart = lib.mkForce [
        ""
        "${mullvadExclude} ${pkgs.tailscale}/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/run/tailscale/tailscaled.sock --port=41641 --tun tailscale0"
      ];
    };

    # Mullvad's routing table (via wg0-mullvad) has higher priority than
    # Tailscale's table, so traffic to 100.64.0.0/10 gets stolen.
    # Add explicit route in the main table — longest-prefix match wins over
    # Mullvad's default route.
    systemd.services.tailscale-mullvad-routes = lib.mkIf config.mySystem.mullvadVpn.enable {
      description = "Add Tailscale routes that bypass Mullvad routing";
      after = [
        "mullvad-daemon.service"
        "tailscaled.service"
      ];
      requires = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.iproute2}/bin/ip route replace 100.64.0.0/10 dev tailscale0 table main
        ${pkgs.iproute2}/bin/ip -6 route replace fd7a:115c:a1e0::/48 dev tailscale0 table main
      '';
    };

    # Allow Tailscale traffic even when Mullvad lockdown mode is active.
    # Mullvad's output chain drops all non-tunnel traffic; this runs at
    # higher priority (-300) so Tailscale traffic is accepted first.
    networking.nftables.tables."tailscale-bypass" = lib.mkIf config.mySystem.mullvadVpn.enable {
      family = "inet";
      content = ''
        chain output {
          type filter hook output priority -300; policy accept;
          oifname "tailscale0" accept comment "Bypass Mullvad lockdown for Tailscale"
          ip daddr 100.64.0.0/10 accept comment "Bypass Mullvad lockdown for Tailscale CGNAT"
          ip6 daddr fd7a:115c:a1e0::/48 accept comment "Bypass Mullvad lockdown for Tailscale IPv6"
        }
        chain input {
          type filter hook input priority -300; policy accept;
          iifname "tailscale0" accept comment "Allow inbound Tailscale traffic"
        }
      '';
    };

    # Split DNS: route .ts.net queries to Tailscale MagicDNS (100.100.100.100).
    # --accept-dns=false keeps Tailscale from managing global DNS, but we still
    # want MagicDNS for Tailscale hostnames. systemd-resolved handles the split:
    #   .ts.net  → 100.100.100.100 (Tailscale MagicDNS)
    #   *        → DNSCrypt proxy (existing config)
    services.resolved.settings.Resolve = {
      Domains = [ "~${tsDomain}" ];
      FallbackDNS = [ constants.tailscaleDns ];
    };
  };
}
