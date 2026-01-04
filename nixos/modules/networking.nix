# Networking and security configuration module
{
  lib,
  user,
  hostname,
  ...
}: {
  # NetworkManager - Enable only on workstations (GUI networking)
  networking.networkmanager.enable = lib.mkDefault (hostname != "server");

  # SSH server - Always enabled with different security settings per host type
  services.openssh = {
    enable = true; # Enable SSH on all hosts

    # Security settings using mkMerge for host-specific configuration
    settings = lib.mkMerge [
      # Common security settings for all hosts
      {
        PermitRootLogin = "no"; # Disable root login everywhere
        PasswordAuthentication = false; # Keys only - no passwords
      }

      # Server-only: Restrict to specific user
      (lib.mkIf (hostname == "server") {
        AllowUsers = [user]; # Only allow specified user on server
      })
    ];
  };

  # Firewall configuration
  networking.firewall = {
    enable = true; # Enable firewall on all hosts

    # Allow ping from outside only on workstations (disable on server for security)
    allowPing = hostname != "server";

    # TCP ports - SSH always available on all hosts (port 22)
    # Additional ports configured in respective modules (nginx, redis, etc.)
    allowedTCPPorts = [22];
  };

  # Server-only: SSH authorized keys for secure remote access
  users.users."${user}" = lib.mkIf (hostname == "server") {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGZ2wUekd/I4jKLlbos1CLvNdfiABE+QgUHGKHcDota pageton@proton.me"
    ];
  };

  # Redis server - Server only, bound to localhost for security
  services.redis.servers."default" = lib.mkIf (hostname == "server") {
    enable = true;
    port = 6379;
    bind = "127.0.0.1"; # Localhost only - no external access
  };
}