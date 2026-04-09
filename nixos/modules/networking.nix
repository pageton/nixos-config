# Networking configuration module.
# NOTE: Firewall rules live in security.nix to keep all hardening in one place.
{ lib, pkgs, ... }:
{
  # NetworkManager for GUI networking
  networking.networkmanager.enable = lib.mkDefault true;
  networking.networkmanager.dns = lib.mkDefault "systemd-resolved";

  # Let NetworkManager and VPN software manage DNS through resolved.
  services.resolved.enable = lib.mkDefault true;

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
