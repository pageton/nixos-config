# SSH client hardening (algorithms, forwarding, host key verification).

{ constants, ... }:

let
  tsHosts = constants.tailscaleHosts;
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        KexAlgorithms = "sntrup761x25519-sha512@openssh.com,curve25519-sha256,curve25519-sha256@libssh.org";
        Ciphers = "chacha20-poly1305@openssh.com,aes256-gcm@openssh.com";
        MACs = "hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com";
        HostKeyAlgorithms = "ssh-ed25519-cert-v01@openssh.com,ssh-ed25519";

        ForwardAgent = "no";
        ForwardX11 = "no";
        AddKeysToAgent = "confirm";
        IdentitiesOnly = "yes";
        StrictHostKeyChecking = "ask";
        VerifyHostKeyDNS = "yes";
        UpdateHostKeys = "yes";
        HashKnownHosts = "yes";

        ServerAliveInterval = "60";
        ServerAliveCountMax = "3";

        ConnectionAttempts = "3";
        ConnectTimeout = "30";
      };

      "github.com" = {
        hostname = "github.com";
        user = "git";
        PreferredAuthentications = "publickey";
      };

      "codeberg.org" = {
        hostname = "codeberg.org";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        AddressFamily = "inet";
        PreferredAuthentications = "publickey";
      };

      "web" = {
        hostname = tsHosts.ads.fqdn;
        user = "root";
        ForwardAgent = "yes";
        ProxyCommand = "/run/current-system/sw/bin/tailscale nc %h %p";
      };

      "server" = {
        hostname = tsHosts.server.fqdn;
        user = "root";
        ForwardAgent = "yes";
        ProxyCommand = "/run/current-system/sw/bin/tailscale nc %h %p";
      };

      "devrio" = {
        hostname = tsHosts.mail.fqdn;
        user = "root";
        ForwardAgent = "yes";
        ProxyCommand = "/run/current-system/sw/bin/tailscale nc %h %p";
      };
    };
  };
}
