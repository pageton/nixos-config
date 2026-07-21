# SSH client hardening (algorithms, forwarding, host key verification).
#
# Server matchBlocks for inventory servers are auto-generated at activation
# time from inventory/permanent/servers.nix (gitignored — never pushed).
# The activation script reads the gitignored file via `nix eval --impure`
# (a shell command, not Nix pure eval) and writes ~/.ssh/config.local.
#
# To add a server: add an entry to inventory/permanent/servers.nix,
# then run `nh home switch`. The SSH config is regenerated automatically.

{ lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Include auto-generated SSH config for inventory servers.
    # Written by the activation script below from gitignored inventory data.
    includes = [ "config.local" ];

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
    };
  };

  # Auto-generate ~/.ssh/config.local from gitignored inventory files.
  # Runs at each `nh home switch` — reads servers.nix via nix eval --impure
  # (shell command, bypasses Nix pure-eval gitignore limitation).
  home.activation.generateSshInventory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PERM="''${HOME}/System/inventory/permanent/servers.nix"
    EPHE="''${HOME}/System/inventory/ephemeral/servers.nix"
    OUT="''${HOME}/.ssh/config.local"
    JQ="${pkgs.jq}/bin/jq"

    # Collect all inventory files that exist.
    FILES=()
    [ -f "''${PERM}" ] && FILES+=("''${PERM}")
    [ -f "''${EPHE}" ] && FILES+=("''${EPHE}")

    # If no inventory files exist, skip (fresh clone before setup).
    [ ''${#FILES[@]} -gt 0 ] || exit 0

    mkdir -p "''${HOME}/.ssh"

    # Generate SSH config from Nix inventory via nix eval + jq.
    {
      echo "# Auto-generated from inventory/*.nix — do not edit manually."
      echo "# Edit inventory/permanent/servers.nix or inventory/ephemeral/servers.nix."
      echo ""

      for f in "''${FILES[@]}"; do
        nix eval --impure --json --expr "import \"''${f}\"" 2>/dev/null \
          | "''${JQ}" -r '
              .[] |
              "Host " + .hostname + "\n" +
              "    HostName " + .ip + "\n" +
              "    User " + (.user // "root") + "\n"
            '
      done
    } > "''${OUT}"

    chmod 600 "''${OUT}"
  '';
}
