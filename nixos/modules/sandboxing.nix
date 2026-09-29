# Application sandboxing with Firejail: wrapped binaries + portal xdg-open shim.
{
  lib,
  pkgs,
  pkgsStable,
  ...
}:
let
  mesaEglVendorFile = "/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json";
  mesaEglFirejailArg = "--env=__EGL_VENDOR_LIBRARY_FILENAMES=${mesaEglVendorFile}";

  # xdg-open replacement used inside firejail jails. Qt's QDesktopServices
  # only talks to the XDG portal from Flatpak/Snap builds; everywhere else it
  # spawns `xdg-open`, which inside a jail resolves the default browser and
  # launches it *inside* the sandbox — where Chromium aborts on startup
  # because its SUID/userns sandbox cannot initialize under the jail's
  # nonewprivs + caps.drop all. This shim forwards every open request to the
  # OpenURI portal instead, so the URL opens in the host's default browser
  # outside the jail. Lives in the store: /nix/store is always visible
  # inside the jail, while $HOME and /tmp are whitelisted/private tmpfs.
  portalXdgOpen = pkgs.writeShellScriptBin "xdg-open" ''
    set -eu
    if [ "$#" -ne 1 ]; then
      echo "usage: xdg-open <url|path>" >&2
      exit 1
    fi
    url=$1
    case "$url" in
      [a-zA-Z]*:*) ;; # has a URI scheme (https://, mailto:, tg://, …)
      /*) url="file://$url" ;;
      *) url="file://$PWD/$url" ;;
    esac
    options="{}"
    token=''${XDG_ACTIVATION_TOKEN:-}
    if [ -n "$token" ] && [[ "$token" =~ ^[A-Za-z0-9._~+-]+$ ]]; then
      options="{\"activation_token\": <\"$token\">}"
    fi
    exec ${lib.getBin pkgs.glib}/bin/gdbus call --session \
      --dest org.freedesktop.portal.Desktop \
      --object-path /org/freedesktop/portal/desktop \
      --method org.freedesktop.portal.OpenURI.OpenURI \
      --timeout 10 "" "$url" "$options"
  '';

  # Firejail entry point that shadows xdg-open with the portal shim by
  # putting it first in PATH inside the jail (private-bin cannot do this on
  # NixOS — binaries live in the store, outside the dirs it privatizes).
  withPortalXdgOpen =
    name: executable:
    pkgs.writeShellScript "${name}-portal-entry" ''
      export PATH="${lib.getBin portalXdgOpen}/bin:$PATH"
      exec ${executable} "$@"
    '';
in
{
  programs.firejail = {
    enable = true;

    # ── HIGH RISK ──────────────────────────────────────────────────────
    # Internet-facing apps with large attack surfaces
    # (rendering engines, media codecs, JavaScript execution)
    # ──────────────────────────────────────────────────────────────────
    wrappedBinaries = {
      # Browsers — use upstream profiles (handle NixOS properly via seccomp)
      # Force Mesa EGL inside sandbox — firejail strips session env vars,
      # so the system-wide override in nvidia.nix doesn't reach sandboxed apps.
      brave = {
        executable = "${lib.getBin pkgs.brave}/bin/brave";
        profile = "${pkgs.firejail}/etc/firejail/brave.profile";
        extraArgs = [ mesaEglFirejailArg ];
      };

      # Messaging — use upstream profiles
      signal-desktop = {
        executable = "${lib.getBin pkgs.signal-desktop}/bin/signal-desktop";
        profile = "${pkgs.firejail}/etc/firejail/signal-desktop.profile";
      };

      # NOTE: telegram-desktop intentionally NOT firejail-wrapped (user
      # request 2026-08-29 — runs unsandboxed).

      wire-desktop = {
        executable = "${lib.getBin pkgsStable.wire-desktop}/bin/wire-desktop";
        profile = "${pkgs.firejail}/etc/firejail/wire-desktop.profile";
      };

      # Media streaming
      freetube = {
        executable = "${lib.getBin pkgs.freetube}/bin/freetube";
        profile = "${pkgs.firejail}/etc/firejail/freetube.profile";
      };

      celluloid = {
        executable = "${lib.getBin pkgsStable.celluloid}/bin/celluloid";
        profile = "${pkgs.firejail}/etc/firejail/celluloid.profile";
      };

      # Discord client (Vencord plugins execute arbitrary JS)
      vesktop = {
        executable = "${lib.getBin pkgs.vesktop}/bin/vesktop";
        profile = "${pkgs.firejail}/etc/firejail/discord.profile";
      };

      # Torrent client
      qbittorrent = {
        executable = "${lib.getBin pkgsStable.qbittorrent}/bin/qbittorrent";
        profile = "${pkgs.firejail}/etc/firejail/qbittorrent.profile";
      };

      # ── MEDIUM RISK ────────────────────────────────────────────────────
      # Network-facing or semi-trusted input, smaller surfaces
      # ──────────────────────────────────────────────────────────────────

      # KeePassXC excluded from firejail — needs SSH agent socket at
      # $XDG_RUNTIME_DIR, D-Bus for Secret Service, and native messaging
      # for browser integration. It encrypts its own database already.

      # Image viewer
      imv = {
        executable = "${lib.getBin pkgsStable.imv}/bin/imv";
        profile = "${pkgs.firejail}/etc/firejail/imv.profile";
      };

      # File sharing over Tor
      onionshare-cli = {
        executable = "${lib.getBin pkgsStable.onionshare}/bin/onionshare-cli";
        profile = "${pkgs.firejail}/etc/firejail/onionshare-cli.profile";
      };

      # Metadata removal
      metadata-cleaner = {
        executable = "${lib.getBin pkgsStable.metadata-cleaner}/bin/metadata-cleaner";
        profile = "${pkgs.firejail}/etc/firejail/metadata-cleaner.profile";
      };

      # System cleaner
      bleachbit = {
        executable = "${lib.getBin pkgsStable.bleachbit}/bin/bleachbit";
        profile = "${pkgs.firejail}/etc/firejail/bleachbit.profile";
      };

      # Database browser
      sqlitebrowser = {
        executable = "${lib.getBin pkgsStable.sqlitebrowser}/bin/sqlitebrowser";
        profile = "${pkgs.firejail}/etc/firejail/sqlitebrowser.profile";
      };
    };
  };

  # Disable tor-browser profile (has hardcoded paths incompatible with NixOS)
  environment = {
    etc = {
      "firejail/tor-browser.profile".enable = false;

      # KeePassXC browser integration — whitelist the browser socket so
      # keepassxc-proxy (spawned inside the firejail sandbox) can reach KeePassXC.
      # Whitelists both the socket, the symlink, and the legacy kpxc_server path.
      "firejail/brave.local".text = ''
        noblacklist ''${RUNUSER}/app
        whitelist ''${RUNUSER}/app/org.keepassxc.KeePassXC
        whitelist ''${RUNUSER}/kpxc_server
        whitelist ''${RUNUSER}/org.keepassxc.KeePassXC.BrowserServer
      '';
    };

    systemPackages = with pkgs; [
      firejail
      bubblewrap
      squashfsTools
    ];
  };

  # Unprivileged user namespaces for Firejail and bubblewrap
  boot.kernel.sysctl = {
    "kernel.unprivileged_userns_clone" = 1;
    "user.max_user_namespaces" = 256;
  };
}
