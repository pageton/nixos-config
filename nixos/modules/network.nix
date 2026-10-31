# Networking: NetworkManager, systemd-resolved, SSH server.
# Firewall rules live in security.nix to keep all hardening in one place.
{ lib, pkgs, ... }: {
  # NetworkManager for GUI networking
  networking.networkmanager = {
    enable = lib.mkDefault true;
    dns = lib.mkDefault "systemd-resolved";
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
    dnsovertls = "opportunistic";
    settings.Resolve = {
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
