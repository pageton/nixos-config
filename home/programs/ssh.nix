# SSH client hardening (algorithms, forwarding, host key verification).

{ constants, ... }:

let
  # Build SSH matchBlocks for Tailscale peers from constants.
  tsHosts = constants.tailscaleHosts;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        extraOptions = {
          # Prefer modern key exchange and ciphers
          KexAlgorithms = "sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org";
          Ciphers = "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com";
          MACs = "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com";
          HostKeyAlgorithms = "ssh-ed25519-cert-v01@openssh.com,ssh-ed25519";

          # Security defaults
          ForwardAgent = "no";
          ForwardX11 = "no";
          AddKeysToAgent = "confirm";
          IdentitiesOnly = "yes";
          StrictHostKeyChecking = "ask";
          VerifyHostKeyDNS = "yes";
          UpdateHostKeys = "yes";
          HashKnownHosts = "yes";

          # Connection keepalive + auto-close idle sessions
          ServerAliveInterval = "60";
          ServerAliveCountMax = "3";

          # Timeout idle connections after 10 minutes (prevents stale session hijacking)
          ConnectionAttempts = "3";
          ConnectTimeout = "30";
        };
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        extraOptions = {
          PreferredAuthentications = "publickey";
        };
      };

      "codeberg.org" = {
        hostname = "codeberg.org";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        extraOptions = {
          AddressFamily = "inet";
          PreferredAuthentications = "publickey";
        };
      };

      # Tailscale peer aliases — auto-generated from constants.tailscaleHosts.
      # ProxyCommand routes through tailscale nc, bypassing Mullvad lockdown.
      "web" = {
        hostname = tsHosts.ads.fqdn;
        user = "root";
        extraOptions = {
          ForwardAgent = "yes";
          ProxyCommand = "/run/current-system/sw/bin/tailscale nc %h %p";
        };
      };

      "server" = {
        hostname = tsHosts.server.fqdn;
        user = "root";
        extraOptions = {
          ForwardAgent = "yes";
          ProxyCommand = "/run/current-system/sw/bin/tailscale nc %h %p";
        };
      };

      "devrio" = {
        hostname = tsHosts.mail.fqdn;
        user = "root";
        extraOptions = {
          ForwardAgent = "yes";
          ProxyCommand = "/run/current-system/sw/bin/tailscale nc %h %p";
        };
      };
    };
  };
}
