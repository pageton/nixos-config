# Telegram Desktop — pageton/tdesktop fork, built from source.
#
# Source: the pageton/tdesktop fork of telegramdesktop/tdesktop, fetched with
# submodules by the pageton-tdesktop flake input (see flake.nix). The input
# tracks the fork's default branch; updates land via
# `nix flake lock update pageton-tdesktop` — no update script or pin to
# maintain.
#
# The build is nixpkgs' telegram-desktop derivation swapped onto the fork
# source. API credentials never enter the repo or the store: the build bakes
# in Telegram's TEST-ONLY pair (the fork's own TDESKTOP_API_TEST cmake
# fallback — too limited to deploy, so a missing secret fails at login
# instead of silently impersonating another client), and the wrappers export
# the real pair at runtime as TG_API_ID/TG_API_HASH from sops-decrypted
# /run/secrets (keys telegram-api-id/telegram-api-hash — see
# nixos/modules/sops.nix). config.h is patched to prefer the env pair over
# the compile-time constants.
#
# Telegram is single-instance per workdir: the second wrapper points at its
# own workdir, making it a fully separate instance (own tdata, settings,
# accounts) instead of just focusing the already-running one.
{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Fork source tree (flake input, fetched with submodules).
  pagetonSrc = inputs.pageton-tdesktop;

  # Version carried by the tree's Telegram/build/version (parsed at eval so a
  # lock update moves the store path name along).
  tgVersion = builtins.head (
    builtins.head (
      builtins.filter (m: m != null) (
        builtins.map (builtins.match "AppVersionStr[[:space:]]+([0-9][.0-9]*)") (
          lib.strings.splitString "\n" (builtins.readFile (pagetonSrc + "/Telegram/build/version"))
        )
      )
    )
  );

  # Runtime override appended to config.h: the inline functions read the
  # compile-time (TEST) constants, then the trailing #defines shadow ApiId /
  # ApiHash so every downstream call site resolves to the env-provided pair.
  # Defining the functions before the macros is what keeps them referring to
  # the constexprs rather than themselves.
  tgConfigHEnvOverride = pkgs.writeText "pageton-config-h-env-override.inc" ''
    // --- nix (home/programs/telegram.nix): runtime API credentials ---
    // Compile-time pair is Telegram's TEST-ONLY credentials; the real pair
    // arrives via TG_API_ID / TG_API_HASH (wrapper exports from sops-managed
    // /run/secrets). Unset/empty env falls back to the TEST pair, which the
    // API server rejects.
    #include <cstdlib>
    inline const char *tgApiHashFromEnv() {
      const char *fromEnv = std::getenv("TG_API_HASH");
      return (fromEnv && *fromEnv) ? fromEnv : ApiHash;
    }
    inline int tgApiIdFromEnv() {
      const char *fromEnv = std::getenv("TG_API_ID");
      return (fromEnv && *fromEnv) ? std::atoi(fromEnv) : int(ApiId);
    }
    #define ApiId (tgApiIdFromEnv())
    #define ApiHash (tgApiHashFromEnv())
  '';

  # nixpkgs' tdesktop build (same pinned nixpkgs), swapped onto the fork
  # source. The Qt wrapper on top brings the image
  # format plugins, the webkitgtk mini-apps webview on LD_LIBRARY_PATH, and
  # the dbus service fixup.
  tdUnwrappedNix = "${pkgs.path}/pkgs/applications/networking/instant-messengers/telegram/telegram-desktop/unwrapped.nix";
  # kdePackages.callPackage: the scope nixpkgs itself uses for tdesktop —
  # it supplies qtbase/qtsvg/qtwayland/qtshadertools/kcoreaddons (top-level
  # Qt attrs no longer exist in current nixpkgs).
  pagetonUnwrapped = (pkgs.kdePackages.callPackage tdUnwrappedNix { }).overrideAttrs (old: {
    pname = "pageton-desktop-unwrapped";
    version = tgVersion;
    src = pagetonSrc;
    # The fork's (newer) lib_ui pulls desktop-app::external_pango — provide
    # pangocairo/pangoft2 via pkg-config.
    buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.pango ];
    # settings.h uses QDir/QFile through transitive includes only; the td_iv
    # precompiled header doesn't pull them in, so include them explicitly.
    postPatch = (old.postPatch or "") + ''
      sed -i 's|#include "base/integration.h"| #include <QDir>\n#include <QFile>\n#include "base/integration.h"|' \
        Telegram/SourceFiles/settings.h
      cat ${tgConfigHEnvOverride} >> Telegram/SourceFiles/config.h
    '';
    # Collect every compile error in one pass instead of one per rebuild.
    NINJAFLAGS = "-k 0";
    # Drop nixpkgs' Snap credentials; keep the rest
    # (e.g. DESKTOP_APP_DISABLE_SWIFT6) untouched. TDESKTOP_API_TEST makes
    # the fork's cmake bake in Telegram's TEST-ONLY pair as the compile-time
    # fallback — the real credentials are runtime env (config.h patch above).
    cmakeFlags =
      builtins.filter (f: !lib.hasInfix "TDESKTOP_API" (toString f)) (old.cmakeFlags or [ ])
      ++ [ (lib.cmakeBool "TDESKTOP_API_TEST" true) ];
  });
  telegramDesktopPkg = pkgs.telegram-desktop.override {
    pname = "pageton-desktop";
    unwrapped = pagetonUnwrapped;
  };

  # NVIDIA EGL fix for mini apps (WebKitGTK webview) — see
  # home/core/desktop-entries.nix for the rationale.
  nvidiaEglEnv = ''
    export GBM_BACKEND=nvidia-drm
    export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
    # The NVIDIA EGL loader only searches /etc/egl and /usr/share/egl for the
    # external-platform configs (libnvidia-egl-wayland: the Wayland/GBM/X11
    # EGL platforms) — point it at the driver bundle or EGL falls back to
    # llvmpipe under native Wayland (QEGLPlatformContext/QRhi errors).
    export __EGL_EXTERNAL_PLATFORM_CONFIG_DIRS=/run/opengl-driver/share/egl/egl_external_platform.d
  '';

  # The session theme env is QT_QPA_PLATFORMTHEME=qt5ct, which Qt6 cannot
  # load, so the send/receive file dialog falls back to a bare theme with an
  # empty sidebar (only Home + "Computer"). This build ships the QGtk3Theme
  # platform theme (libqgtk3.so in nixpkgs qtbase), so the gtk3 dialog keeps
  # reading ~/.config/gtk-3.0/bookmarks and the XDG user dirs. Scoped to
  # Telegram only — the rest of the session keeps qt5ct styling.
  fileDialogThemeEnv = ''
    export QT_QPA_PLATFORMTHEME=gtk3
  '';

  # Common wrapper env — see the blocks above for what each export fixes.
  # Store is read-only, so the built-in updater could never install anything
  # anyway; -noupdate keeps it from asking.
  wrapperEnv = ''
    ${nvidiaEglEnv}
    ${fileDialogThemeEnv}
    # API credentials from sops (nixos/modules/sops.nix decrypts them to
    # /run/secrets at system activation). Hard-fail when missing: without
    # them the app would silently run on the TEST-ONLY pair.
    for secret in /run/secrets/telegram-api-id /run/secrets/telegram-api-hash; do
      if [[ ! -r $secret ]]; then
        echo "telegram-desktop: missing/unreadable $secret — apply the system config (just nixos) first" >&2
        exit 1
      fi
    done
    export TG_API_ID="$(< /run/secrets/telegram-api-id)"
    export TG_API_HASH="$(< /run/secrets/telegram-api-hash)"
    # Session-wide for Kvantum-styled Qt apps, but this build only ships
    # Fusion/Windows styles — the override can never load and just prints a
    # warning on every start.
    unset QT_STYLE_OVERRIDE
    export XKB_CONFIG_ROOT=${pkgs.xkeyboard_config}/share/X11/xkb
    # Mini-apps webview runtime, per the fork's own flake.nix devShell (the
    # webview dlopens webkitgtk-4.1 — the nixpkgs Qt wrapper already
    # LD_LIBRARY_PATHs it with geoclue2 — and the helper inherits this env):
    # a session GDK_BACKEND pin breaks the helper's own backend pinning, and
    # WebKit's DMABUF renderer fails to allocate GBM buffers on the
    # proprietary NVIDIA driver (mini apps render empty) — shared-memory
    # buffers via the UI-process switch instead.
    unset GDK_BACKEND
    export WEBKIT_DISABLE_DMABUF_RENDERER=1
  '';

  telegramDesktop = pkgs.writeShellScriptBin "telegram-desktop" ''
    set -euo pipefail
    ${wrapperEnv}
    exec ${lib.getBin telegramDesktopPkg}/bin/Telegram -noupdate "$@"
  '';

  telegramDesktopSecond = pkgs.writeShellScriptBin "telegram-desktop-second" ''
    set -euo pipefail
    workdir="''${XDG_DATA_HOME:-$HOME/.local/share}/TelegramDesktopSecond"
    mkdir -p "$workdir"
    ${wrapperEnv}
    exec ${lib.getBin telegramDesktopPkg}/bin/Telegram -noupdate -workdir "$workdir" "$@"
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
    comment = "Pageton Telegram Desktop client (unsandboxed)";
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
    comment = "Second Pageton Telegram Desktop client (unsandboxed, separate profile)";
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
}
