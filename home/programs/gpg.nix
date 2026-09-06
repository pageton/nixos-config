{
  pkgs,
  pkgsStable,
  lib,
  ...
}:
{
  programs.gpg = {
    enable = true;

    settings = {
      personal-cipher-preferences = "AES256";
      personal-digest-preferences = "SHA512";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      default-preference-list = "SHA512 AES256 ZLIB BZIP2 ZIP Uncompressed";
      cert-digest-algo = "SHA512";
      s2k-digest-algo = "SHA512";
      s2k-cipher-algo = "AES256";
      charset = "utf-8";
      fixed-list-mode = true;
      no-comments = true;
      no-emit-version = true;
      no-greeting = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-key-origin = true;
      require-cross-certification = true;
      no-symkey-cache = true;
      throw-keyids = true;
    };
  };

  services.gpg-agent = lib.mkIf (!pkgsStable.stdenv.hostPlatform.isDarwin) {
    enable = true;
    # Passphrase once per boot: the cache lives in RAM only (cleared when the
    # agent restarts), so a long TTL is safe relative to disk-based caches.
    # maxCacheTtl must be raised explicitly — GnuPG caps caching at 2h by
    # default, silently overriding defaultCacheTtl.
    defaultCacheTtl = 604800;
    maxCacheTtl = 604800;
    # Avoid gpg-agent hijacking SSH auth; OpenSSH should use ~/.ssh/id_ed25519 directly.
    enableSshSupport = false;
    pinentry.package = pkgsStable.pinentry-curses;
    # Allow loopback mode for non-interactive environments (e.g., CI, scripts without TTY)
    extraConfig = ''
      allow-loopback-pinentry
      allow-preset-passphrase
    '';
  };

  # Password-free commit signing: feed the key passphrase to gpg-agent from
  # the SOPS-decrypted secret at login, so signing works all session without
  # pinentry. The daily timer re-presets past the 7d max-cache-ttl for
  # sessions that outlive it. Passphrase stays on tmpfs (/run/secrets) and in
  # the age-encrypted secrets.yaml — never plaintext on disk.
  systemd.user = {
    services.gpg-preset-passphrase = {
      Unit = {
        Description = "Preset GPG signing key passphrase into gpg-agent";
        # Skip cleanly on hosts where the system switch hasn't materialized the secret.
        ConditionPathExists = [ "/run/secrets/gpg-passphrase" ];
      };
      Service = {
        Type = "oneshot";
        Environment = [ "GNUPGHOME=%h/.gnupg" ];
        ExecStart = pkgs.writeShellScript "gpg-preset" ''
          set -euo pipefail
          ${pkgsStable.gnupg}/bin/gpgconf --launch gpg-agent
          printf '%s\n' "$(< /run/secrets/gpg-passphrase)" \
            | ${pkgsStable.gnupg}/libexec/gpg-preset-passphrase \
              --preset 3CB35D13C6BEAA98F9F841B2160A36D9DFD1BC75
        '';
      };
      Install.WantedBy = [ "default.target" ];
    };

    timers.gpg-preset-passphrase = {
      Unit.Description = "Daily GPG passphrase re-preset (outlives cache TTL)";
      Timer = {
        OnCalendar = "daily";
        RandomizedDelaySec = "10m";
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
