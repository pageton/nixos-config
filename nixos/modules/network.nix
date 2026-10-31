# Networking: NetworkManager, systemd-resolved, SSH server.
# Firewall rules live in security.nix to keep all hardening in one place.
{ lib, pkgs, ... }: {
  # NetworkManager for GUI networking
  networking.networkmanager = {
    enable = lib.mkDefault true;
    # "none": do NOT register the DHCP resolver (ISP DNS) as per-link
    # DNS with systemd-resolved. resolved prefers link scopes over the
    # global scope, so the ISP resolver would keep intercepting all
    # queries and defeat the global DoT servers below. With "none",
    # every lookup goes to the encrypted global resolvers. VPN daemons
    # (WARP/Mullvad/Tailscale) manage their own DNS and don't rely on
    # NM registration.
    dns = lib.mkForce "none";
    wifi.macAddress = "random";
    ethernet.macAddress = "random";
  };

  # Let NetworkManager and VPN software manage DNS through resolved.
  #
  # Encrypted DNS (DoT) + global default route: the ISP resolver
  # intermittently drops lookups for foreign domains (e.g. zcode.z.ai /
  # cdn-zcode.z.ai -> ENOTFOUND), which broke the Z.ai IDE with
  # "Reconnecting..." unless a VPN (WARP/Mullvad) was up. DoT lookups to
  # Cloudflare/Google bypass the plaintext resolver path entirely
  # (port 853 verified reachable from this line without a VPN).
  # "opportunistic" falls back to plaintext if DoT is ever blocked, so
  # DNS keeps working either way.
  services.resolved = {
    enable = lib.mkDefault true;
    settings.Resolve = {
      DNSOverTLS = "opportunistic";
      DNS = [
        "1.1.1.1#cloudflare-dns.com"
        "8.8.8.8#dns.google"
      ];
      # Route all non-link-specific queries to the global DoT servers
      # instead of the ISP resolver from DHCP. More-specific routing
      # domains (e.g. ~ts.net from tailscale.nix) still win for their
      # own suffix.
      Domains = [ "~." ];
    };
  };

  # Pin the zcode.z.ai API host to the CDN edge that is fast and stable
  # from this line. The initaa CDN rotates answers across PoPs; the
  # 43.109.215.x range it often hands out is heavily throttled here
  # (3-4s handshakes, intermittent connect timeouts -> zcode
  # "Reconnecting..."), while 155.102.149.17 measures a stable ~0.3s
  # (re-verified across 90 minutes). .48 kept as second address for
  # failover — Node's connect logic tries every A record.
  # If zcode ever fails to connect again: remove these entries (let DNS
  # choose) and re-time candidate edges:
  #   curl -o /dev/null -w '%{time_total}\n' \
  #     --resolve zcode.z.ai:443:<ip> https://zcode.z.ai/api/v1/mcp/usage
  networking.hosts = {
    "155.102.149.17" = [ "zcode.z.ai" ];
    "155.102.149.48" = [ "zcode.z.ai" ];
  };

  # Reduce boot blocking from wait-online while keeping deterministic network startup.
  # nm-online default timeout is high; this caps startup stall on slow links.
  systemd.services.NetworkManager-wait-online.serviceConfig = {
    ExecStart = lib.mkForce "${pkgs.networkmanager}/bin/nm-online -q --timeout=15";
    TimeoutStartSec = lib.mkForce "20s";
  };

  # SSH server — key-only auth, password disabled
  # Access control: firewall (security.nix) + Tailscale ACLs
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
