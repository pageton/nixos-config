# Application sandboxing with Firejail and bubblewrap.
{
  config,
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
  options.mySystem.sandboxing = {
    enable = lib.mkEnableOption "application sandboxing with Firejail and bubblewrap";

    enableUserNamespaces = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = true;
      description = "Enable unprivileged user namespaces for Firejail and bubblewrap. Required for bubblewrap and modern sandbox features.";
    };

    enableWrappedBinaries = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Enable Firejail's wrapped binaries for automatic sandboxing of common applications (browsers, office suites, etc.).";
    };
  };

  config = lib.mkIf config.mySystem.sandboxing.enable {
    programs.firejail = {
      enable = true;
      wrappedBinaries = lib.mkIf config.mySystem.sandboxing.enableWrappedBinaries {
        # ── HIGH RISK ──────────────────────────────────────────────────────
        # Internet-facing apps with large attack surfaces
        # (rendering engines, media codecs, JavaScript execution)
        # ──────────────────────────────────────────────────────────────────

        # Browsers — use upstream profiles (handle NixOS properly via seccomp)
        # Force Mesa EGL inside sandbox — firejail strips session env vars,
        # so the system-wide override in nvidia.nix doesn't reach sandboxed apps.
        brave = {
          executable = "${pkgs.lib.getBin pkgs.brave}/bin/brave";
          profile = "${pkgs.firejail}/etc/firejail/brave.profile";
          extraArgs = [ mesaEglFirejailArg ];
        };

        # LibreWolf (Firefox-based) — custom profile extends firefox-common
        # (firefox.profile hardcodes "firefox" in private-bin, blocking the "librewolf" binary).
        # Force Mesa EGL inside sandbox — firejail strips session env vars,
        # so the system-wide override in nvidia.nix doesn't reach sandboxed apps.
        librewolf = {
          executable = "${pkgs.lib.getBin pkgsStable.librewolf}/bin/librewolf";
          profile = "${pkgs.firejail}/etc/firejail/librewolf.profile";
          extraArgs = [ mesaEglFirejailArg ];
        };

        # Messaging — use upstream profiles
        signal-desktop = {
          executable = "${pkgs.lib.getBin pkgs.signal-desktop}/bin/signal-desktop";
          profile = "${pkgs.firejail}/etc/firejail/signal-desktop.profile";
        };

        # NOTE: telegram-desktop intentionally NOT firejail-wrapped (user
        # request 2026-08-29 — runs unsandboxed). AyuGram (below) still uses
        # the telegram profile + telegram.local, which is why that profile's
        # local overrides stay in place.

        ayugram-desktop = {
          executable = withPortalXdgOpen "ayugram-desktop" "${lib.getBin pkgs.ayugram-desktop}/bin/AyuGram";
          profile = "${pkgs.firejail}/etc/firejail/telegram-desktop.profile";
        };

        wire-desktop = {
          executable = "${pkgs.lib.getBin pkgsStable.wire-desktop}/bin/wire-desktop";
          profile = "${pkgs.firejail}/etc/firejail/wire-desktop.profile";
        };

        # Media streaming
        freetube = {
          executable = "${pkgs.lib.getBin pkgs.freetube}/bin/freetube";
          profile = "${pkgs.firejail}/etc/firejail/freetube.profile";
        };

        celluloid = {
          executable = "${pkgs.lib.getBin pkgsStable.celluloid}/bin/celluloid";
          profile = "${pkgs.firejail}/etc/firejail/celluloid.profile";
        };

        # Discord client (Vencord plugins execute arbitrary JS)
        vesktop = {
          executable = "${pkgs.lib.getBin pkgs.vesktop}/bin/vesktop";
          profile = "${pkgs.firejail}/etc/firejail/discord.profile";
        };

        # Torrent client
        qbittorrent = {
          executable = "${pkgs.lib.getBin pkgsStable.qbittorrent}/bin/qbittorrent";
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
          executable = "${pkgs.lib.getBin pkgsStable.imv}/bin/imv";
          profile = "${pkgs.firejail}/etc/firejail/imv.profile";
        };

        # Office suite
        # libreoffice = {
        #   executable = "${pkgs.lib.getBin pkgsStable.libreoffice-qt6-fresh}/bin/libreoffice";
        #   profile = "${pkgs.firejail}/etc/firejail/libreoffice.profile";
        # };

        # File sharing over Tor
        onionshare-cli = {
          executable = "${pkgs.lib.getBin pkgsStable.onionshare}/bin/onionshare-cli";
          profile = "${pkgs.firejail}/etc/firejail/onionshare-cli.profile";
        };

        # Metadata removal
        metadata-cleaner = {
          executable = "${pkgs.lib.getBin pkgsStable.metadata-cleaner}/bin/metadata-cleaner";
          profile = "${pkgs.firejail}/etc/firejail/metadata-cleaner.profile";
        };

        # System cleaner
        bleachbit = {
          executable = "${pkgs.lib.getBin pkgsStable.bleachbit}/bin/bleachbit";
          profile = "${pkgs.firejail}/etc/firejail/bleachbit.profile";
        };

        # Database browser
        sqlitebrowser = {
          executable = "${pkgs.lib.getBin pkgsStable.sqlitebrowser}/bin/sqlitebrowser";
          profile = "${pkgs.firejail}/etc/firejail/sqlitebrowser.profile";
        };
      };
    };

    # Disable tor-browser profile (has hardcoded paths incompatible with NixOS)
    # and create a librewolf profile (firefox.profile hardcodes "firefox" binary name).
    environment = {
      etc = {
        "firejail/tor-browser.profile".enable = false;

        # LibreWolf firejail profile — extends firefox-common (the actual sandbox rules)
        # instead of firefox.profile (which hardcodes private-bin firefox).
        "firejail/librewolf.profile".text = ''
          # LibreWolf — Firefox-based, uses same sandbox rules as Firefox.
          # Extends firefox-common (which contains the actual restrictions) but
          # uses "librewolf" as the binary name instead of "firefox".
          include firefox-common.profile
          private-bin librewolf, sh, bash, cat, mkdir, ln, rm, grep, sed, awk
        '';

        # KeePassXC browser integration — whitelist the browser socket so
        # keepassxc-proxy (spawned inside the firejail sandbox) can reach KeePassXC.
        # Whitelists both the socket, the symlink, and the legacy kpxc_server path.
        "firejail/brave.local".text = ''
          noblacklist ''${RUNUSER}/app
          whitelist ''${RUNUSER}/app/org.keepassxc.KeePassXC
          whitelist ''${RUNUSER}/kpxc_server
          whitelist ''${RUNUSER}/org.keepassxc.KeePassXC.BrowserServer
        '';

        # Apply same KeePassXC whitelist to LibreWolf
        "firejail/librewolf.local".text = ''
          noblacklist ''${RUNUSER}/app
          whitelist ''${RUNUSER}/app/org.keepassxc.KeePassXC
          whitelist ''${RUNUSER}/kpxc_server
          whitelist ''${RUNUSER}/org.keepassxc.KeePassXC.BrowserServer
        '';

        # Telegram drag-and-drop support for files outside ~/Downloads.
        "firejail/telegram.local".text = ''
          # AyuGram persistence (it uses Telegram-compatible profile but stores
          # state under AyuGram-specific directories).
          noblacklist ''${HOME}/.AyuGramDesktop
          noblacklist ''${HOME}/.local/share/AyuGramDesktop
          noblacklist ''${HOME}/.local/share/ayugram-desktop
          noblacklist ''${HOME}/.config/AyuGramDesktop

          mkdir ''${HOME}/.AyuGramDesktop
          mkdir ''${HOME}/.local/share/AyuGramDesktop
          mkdir ''${HOME}/.local/share/ayugram-desktop
          mkdir ''${HOME}/.config/AyuGramDesktop

          whitelist ''${HOME}/.AyuGramDesktop
          whitelist ''${HOME}/.local/share/AyuGramDesktop
          whitelist ''${HOME}/.local/share/ayugram-desktop
          whitelist ''${HOME}/.config/AyuGramDesktop

          noblacklist ''${HOME}/Documents
          noblacklist ''${HOME}/Pictures
          noblacklist ''${HOME}/Videos
          noblacklist ''${HOME}/Music
          noblacklist ''${HOME}/Desktop

          whitelist ''${HOME}/Documents
          whitelist ''${HOME}/Pictures
          whitelist ''${HOME}/Videos
          whitelist ''${HOME}/Music
          whitelist ''${HOME}/Desktop

          # Link opening: the portalXdgOpen shim (see top of this file)
          # delegates URL handling to xdg-desktop-portal's OpenURI
          # interface, so the browser launches on the host, outside the
          # jail. The upstream profile uses dbus-user filter (whitelist
          # mode) which blocks portal calls, so the portal must be allowed
          # explicitly.
          dbus-user.talk org.freedesktop.portal.Desktop
          dbus-user.talk org.freedesktop.impl.portal.FileChooser

          # NVIDIA EGL webview fix (mini apps): force the NVIDIA GBM backend and
          # EGL vendor so WebKitGTK's renderer doesn't fall back to Mesa on the
          # NVIDIA device ("driver (null)" → qt.waylandcompositor EGL failure).
          # Matches the env in home/programs/telegram.nix (telegram-desktop
          # wrappers); kept here so AyuGram's webview gets it too.
          env GBM_BACKEND=nvidia-drm
          env __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
        '';
      };

      systemPackages = with pkgs; [
        firejail
        bubblewrap
        squashfsTools
      ];
    };

    boot.kernel.sysctl = lib.mkIf config.mySystem.sandboxing.enableUserNamespaces {
      "kernel.unprivileged_userns_clone" = 1;
      "user.max_user_namespaces" = 256;
    };
  };
}
