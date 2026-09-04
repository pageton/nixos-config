# Telegram Desktop — official GitHub-release binary (pinned + auto-bumped).
#
# Source: tsetup.<version>.tar.xz from
# https://github.com/telegramdesktop/tdesktop/releases — a near-static build
# (Qt + media stack baked in; only glib/freetype/fontconfig load dynamically),
# so updates land on release day instead of trailing the nixpkgs source build
# by weeks. scripts/apps/telegram-update.sh runs from the daily
# telegram-update timer below to bump the pin and, when the working tree was
# clean, apply it with `just home`.
#
# The tarball ships no .desktop/icons — icons are vendored in ./telegram-icons
# (upstream artwork; also serves AyuGram's entry in home/core/
# desktop-entries.nix) and the desktop entries live below, keeping tg://
# bound to the primary instance.
#
# Telegram is single-instance per workdir: the second wrapper points at its
# own workdir, making it a fully separate instance (own tdata, settings,
# accounts) instead of just focusing the already-running one.
{
  lib,
  pkgs,
  hmSystemdHelpers,
  ...
}:

let
  # ── Pin — auto-updated by scripts/apps/telegram-update.sh (keep attr names) ──
  tgVersion = "7.1.5";
  # sha256 of tsetup.<tgVersion>.tar.xz from the release asset's `digest`.
  tgHash = "sha256-hhWMnNpeQjEPimWGmpMp2r1gFo50vooy1ZchAew0Wys=";

  # NVIDIA EGL fix for mini apps (WebKitGTK webview) — see
  # home/core/desktop-entries.nix for the rationale.
  nvidiaEglEnv = ''
    export GBM_BACKEND=nvidia-drm
    export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
  '';

  # The session theme env is QT_QPA_PLATFORMTHEME=qt5ct, which Qt6 cannot
  # load, so the send/receive file dialog falls back to a bare theme with an
  # empty sidebar (only Home + "Computer"). The official build ships the
  # QGtk3Theme platform theme (statically), so the gtk3 dialog keeps reading
  # ~/.config/gtk-3.0/bookmarks and the XDG user dirs. Scoped to Telegram
  # only — the rest of the session keeps qt5ct styling.
  fileDialogThemeEnv = ''
    export QT_QPA_PLATFORMTHEME=gtk3
  '';

  # Install-only package — the ELF stays pristine. autoPatchelfHook is
  # forbidden here: rewriting PT_INTERP to the longer store path corrupts
  # relocations in this unusual 227MB near-static layout (SIGILL in
  # __libc_csu_init at base+0x31c, verified 2026-09-02). Instead the
  # wrappers below exec the store glibc loader explicitly.
  telegramDesktopPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "telegram-desktop-official";
    version = tgVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/telegramdesktop/tdesktop/releases/download/v${tgVersion}/tsetup.${tgVersion}.tar.xz";
      hash = tgHash;
    };

    installPhase = ''
      runHook preInstall

      # Named org.telegram.desktop so the GTK3 file dialog window (whose
      # Wayland app-id GLib derives from /proc/self/exe) reports the same
      # app-id as every Qt window — matches home/desktop/niri/rules.nix.
      # `Telegram` stays as the canonical name for wrappers/CLI.
      install -Dm755 ./Telegram "$out/bin/org.telegram.desktop"
      ln -s org.telegram.desktop "$out/bin/Telegram"

      # The tarball has no icons; the vendored hicolor set covers this entry
      # and AyuGram's (home/core/desktop-entries.nix reuses the name).
      mkdir -p "$out/share/icons"
      cp -r "${./telegram-icons}/hicolor" "$out/share/icons/hicolor"

      # Updater is intentionally not installed: the store is read-only and
      # the pin above replaces it (wrappers pass -noupdate).

      runHook postInstall
    '';
  };

  # The binary's DT_NEEDED is tiny (glib/freetype/fontconfig + system
  # audio), but its statically-linked Qt dlopens the rest at startup:
  # wayland-client (platform plugin), gdk/gtk3 (QGtk3Theme file dialog),
  # EGL/GL (glvnd + the NVIDIA vendor dir), libxkbcommon (+ keymap data),
  # and — for mini apps — webkitgtk. Resolved via the explicit loader
  # invocation below instead of an ELF rpath (no patchelf, see above).
  tgLoader = "${lib.getLib pkgs.stdenv.cc.libc}/lib/ld-linux-x86-64.so.2";
  tgLibPath =
    lib.makeLibraryPath (
      with pkgs;
      [
        glib
        freetype
        fontconfig
        alsa-lib
        pipewire
        libpulseaudio
        dbus
        wayland
        libxkbcommon
        gtk3
        libglvnd
        webkitgtk_6_0
      ]
    )
    + ":/run/opengl-driver/lib";

  # Common wrapper env — see the blocks above for what each export fixes.
  # NIX_LD/NIX_LD_LIBRARY_PATH cover children that re-exec through the
  # original /lib64 interpreter (the nix-ld shim), e.g. the webview helper.
  # No GStreamer env: the official build's media stack is baked in.
  wrapperEnv = ''
    ${nvidiaEglEnv}
    ${fileDialogThemeEnv}
    # Session-wide for Kvantum-styled Qt apps, but the official build's
    # static Qt only ships Windows/Fusion styles — the override can never
    # load and just prints a warning on every start.
    unset QT_STYLE_OVERRIDE
    export XKB_CONFIG_ROOT=${pkgs.xkeyboard_config}/share/X11/xkb
    export NIX_LD=${tgLoader}
    export NIX_LD_LIBRARY_PATH=${tgLibPath}
  '';

  telegramDesktop = pkgs.writeShellScriptBin "telegram-desktop" ''
    set -euo pipefail
    ${wrapperEnv}
    exec ${tgLoader} --library-path ${tgLibPath} ${lib.getBin telegramDesktopPkg}/bin/Telegram -noupdate "$@"
  '';

  telegramDesktopSecond = pkgs.writeShellScriptBin "telegram-desktop-second" ''
    set -euo pipefail
    workdir="''${XDG_DATA_HOME:-$HOME/.local/share}/TelegramDesktopSecond"
    mkdir -p "$workdir"
    ${wrapperEnv}
    exec ${tgLoader} --library-path ${tgLibPath} ${lib.getBin telegramDesktopPkg}/bin/Telegram -noupdate -workdir "$workdir" "$@"
  '';
in
{
  home.packages = [
    telegramDesktop
    telegramDesktopSecond
  ];

  xdg.desktopEntries."org.telegram.desktop" = {
    name = "Telegram Desktop";
    exec = "${telegramDesktop}/bin/telegram-desktop -- %U";
    icon = "org.telegram.desktop";
    comment = "Official Telegram Desktop client (unsandboxed)";
    categories = [
      "Chat"
      "Network"
      "InstantMessaging"
      "Qt"
    ];
    mimeType = [
      "x-scheme-handler/tg"
      "x-scheme-handler/tonsite"
    ];
    settings = {
      StartupWMClass = "TelegramDesktop";
      DBusActivatable = "true";
      SingleMainWindow = "true";
      Keywords = "tg;chat;im;messaging;messenger;sms;tdesktop;";
    };
    actions = {
      quit = {
        name = "Quit Telegram";
        exec = "${telegramDesktop}/bin/telegram-desktop -quit";
        icon = "application-exit";
      };
    };
  };

  xdg.desktopEntries."org.telegram.desktop.second" = {
    name = "Telegram Desktop Second";
    exec = "${telegramDesktopSecond}/bin/telegram-desktop-second -- %U";
    icon = "org.telegram.desktop";
    comment = "Second official Telegram Desktop client (unsandboxed, separate profile)";
    categories = [
      "Chat"
      "Network"
      "InstantMessaging"
      "Qt"
    ];
    # No mimeType on purpose: tg:// and tonsite:// links stay bound to the
    # primary instance's entry (home/core/desktop-entries.nix).
    settings = {
      StartupWMClass = "TelegramDesktop";
      SingleMainWindow = "true";
      Keywords = "tg;chat;im;messaging;messenger;sms;tdesktop;second;";
    };
    actions = {
      quit = {
        name = "Quit Telegram Second";
        exec = "${telegramDesktopSecond}/bin/telegram-desktop-second -quit";
        icon = "application-exit";
      };
    };
  };

  # ── Daily pin bump ──
  # scripts/apps/telegram-update.sh rewrites tgVersion/tgHash from the latest
  # GitHub release (asset `digest` → SRI, no build-fail hash hunt) and, only
  # when the working tree was clean before the bump, applies it via
  # `just home` — a dirty tree gets the bump but no unreviewed switch. It
  # never commits; the change stays in the working tree for review.
  systemd.user.services.telegram-update = {
    Unit = {
      Description = "Bump Telegram Desktop pin to the latest tdesktop release";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      # User-manager PATH lacks the HM profile (just) and flake tooling (nix,
      # nh via the system path).
      Environment = [
        "PATH=%h/.nix-profile/bin:/run/current-system/sw/bin:/usr/bin:/bin"
        "HOME=%h"
      ];
      ExecStart = "${pkgs.bash}/bin/bash %h/System/scripts/apps/telegram-update.sh";
    };
  };

  systemd.user.timers.telegram-update = hmSystemdHelpers.mkHmTimer {
    description = "Daily Telegram Desktop pin bump";
    onCalendar = "daily";
    randomizedDelaySec = "30m";
  };
}
