# Tailscale is a VPN service that makes it easy to connect your devices between each other.
{
  user,
  pkgsStable,
  ...
}: {
  security.sudo.extraRules = [
    {
      users = [user];
      # Allow running Tailscale commands without a password
      commands = [
        {
          command = "/etc/profiles/per-user/${user}/bin/tailscale";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/tailscale";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];

  services.tailscale = {
    enable = true;
    package = pkgsStable.tailscale;
    openFirewall = true;
  };

  networking.firewall = {
    trustedInterfaces = ["tailscale0"];
    # required to connect to Tailscale exit nodes
    checkReversePath = "loose";
  };
}
