# Tailscale is a VPN service that makes it easy to connect your devices between each other.
{
  lib,
  user,
  pkgsStable,
  ...
}:
{
  security.sudo.extraRules = [
    {
      users = [ user ];
      # Allow running Tailscale commands without a password
      commands = [
        {
          command = "/etc/profiles/per-user/${user}/bin/tailscale";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/tailscale";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  services.tailscale = {
    enable = true;
    package = pkgsStable.tailscale;
    openFirewall = false;
  };

  # Avoid pulling full network-online critical path into boot.
  # tailscaled tolerates late network availability and reconnects automatically.
  systemd.services.tailscaled = {
    after = lib.mkForce [
      "network.target"
      "network-pre.target"
    ];
    wants = lib.mkForce [ "network.target" ];
  };

  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    # required to connect to Tailscale exit nodes
    checkReversePath = "loose";
  };
}
