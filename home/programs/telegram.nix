# Telegram Desktop — pageton/tdesktop fork, prebuilt release binary.
#
# Source: the fork's GitHub release tarball
# (https://github.com/pageton/tdesktop/releases — td-setup-linux-x64), pinned
# by tgVersion below. Updates land by bumping tgVersion + the fetchurl hash
# (nix-prefetch-url the new URL, convert to SRI with `nix hash convert`).
# No source build: the tarball ships a mostly-static binary (Qt, tgcalls,
# lib_ui, ffmpeg baked in).
#
# Two non-obvious constraints, both worked around in this file:
#
# 1. patchelf is unusable. Any --set-interpreter/--set-rpath rewrite of this
#    ~280MB multi-segment static binary corrupts it — the patched binary
#    jumps into its own ELF headers during init_array (SIGILL/SIGSEGV,
#    verified). Instead the stock PT_INTERP payload "/lib64/ld-linux-x86-64.so.2"
#    (27 bytes) is overwritten IN PLACE with a shorter path (tgLoaderPath)
#    and NUL-padded: pure string rewrite, no header/segment/size changes.
#    The wrapper keeps a symlink at tgLoaderPath pointing at the pinned nix
#    glibc loader, so the kernel can exec the binary directly.
#
# 2. Running through nix-ld instead is NOT an option: nix-ld execs the real
#    glibc loader as the process image, so /proc/self/exe is the LOADER, not
#    Telegram. The app derives its executable path from /proc/self/exe and
#    re-execs itself to spawn the mini-apps webview helper — with the loader
#    as the image the helper spawn execs "/path/to/ld.so -webviewhelper …"
#    and the loader dies trying to open a file named "-webviewhelper". With
#    the byte-patched interpreter the kernel execs Telegram itself and
#    /proc/self/exe is correct in the app AND the helper.
#
# API credentials are whatever the fork bakes into its release (their
# production pair, built from CI secrets). The config.h env-override hack the
# old source build used is compile-time only and cannot apply to a prebuilt
# binary — the sops telegram-api-id/telegram-api-hash secrets are unused.
# This is standard fork behavior; login works normally with the fork's pair
# (the first start after this switch may ask to log in again, since the
# existing sessions were authenticated under a different api_id).
#
# App-id: the release build has its internal updater enabled at compile time,
# which makes it derive its Wayland app-id as org.telegram.desktop._<hash>
# instead of the plain org.telegram.desktop the niri rules match. The
# wrappers drop an external-updater marker (<workdir>/externalupdater.d/)
# containing the executable path; the app reads it at startup, sets
# UpdaterDisabled, and keeps the plain app-id (niri rules, pop-out windows,
# and the auth-float script all match on the unsuffixed id).
#
# Telegram is single-instance per workdir: the second wrapper points at its
# own workdir, making it a fully separate instance (own tdata, settings,
# accounts) instead of just focusing the already-running one.
{ lib, pkgs, ... }:

let
  # Release version pin; the tarball URL is derived from it.
  tgVersion = "7.2.7";

  # Short path the PT_INTERP payload is byte-patched to (must stay shorter
  # than the stock 27-byte "/lib64/ld-linux-x86-64.so.2"). The wrapper
  # creates/verifies a symlink here on every launch — see the header.
  tgLoaderPath = "/tmp/tgld";

  telegramDesktopPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "pageton-desktop";
    version = tgVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/pageton/tdesktop/releases/download/v${tgVersion}/td-setup-linux-x64-${tgVersion}.tar.xz";
      hash = "sha256-oL4NANuPZX0sWSK4Sicwnak4ib/idFY/nFvLXZ31a/k=";
    };

    dontConfigure = true;
    dontBuild = true;

    # The tarball's only entry is the Telegram/ directory (binary + Updater).
    # Updater is dropped on purpose: the wrappers run -noupdate and the
    # store is read-only, so the built-in updater can never work.
    sourceRoot = "Telegram";

    installPhase = ''
      runHook preInstall
      install -Dm755 Telegram $out/libexec/Telegram

      # Byte-patch the PT_INTERP payload in place (see header): find the
      # stock interpreter string, assert it is unique, overwrite it with
      # tgLoaderPath and NUL-pad the remainder.
      from='/lib64/ld-linux-x86-64.so.2'
      to='${tgLoaderPath}'
      if (( ''${#to} > ''${#from} )); then
        echo "tgLoaderPath (''${#to} bytes) must not be longer than $from (''${#from} bytes)" >&2
        exit 1
      fi
      interpOff=$(grep -abo "$from" $out/libexec/Telegram | head -1 | cut -d: -f1)
      test -n "$interpOff" || { echo "interpreter string not found" >&2; exit 1; }
      test "$(grep -abo "$from" $out/libexec/Telegram | wc -l)" -eq 1 \
        || { echo "interpreter string is not unique" >&2; exit 1; }
      printf '%s' "$to" | dd of=$out/libexec/Telegram bs=1 seek="$interpOff" conv=notrunc status=none
      dd if=/dev/zero bs=1 count=$(( ''${#from} - ''${#to} )) \
        | dd of=$out/libexec/Telegram bs=1 seek=$(( interpOff + ''${#to} )) conv=notrunc status=none

      runHook postInstall
    '';
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
  # empty sidebar (only Home + "Computer"). The static build ships the
  # QGtk3Theme platform theme, so with gtk3 dlopenable (see runtimeLibsEnv)
  # the gtk3 dialog keeps reading ~/.config/gtk-3.0/bookmarks and the XDG
  # user dirs. Scoped to Telegram only — the rest of the session keeps qt5ct
  # styling.
  fileDialogThemeEnv = ''
    export QT_QPA_PLATFORMTHEME=gtk3
  '';

  # NixOS has no ld.so.cache and the binary is unpatched (see header), so
  # EVERYTHING resolves from here: DT_NEEDED (glib/pango/cairo/fontconfig/
  # freetype), the .note.dlopen metadata (pipewire/pulseaudio/alsa backends +
  # dbus), and plain dlopens (wayland + xkbcommon at startup, webkitgtk for
  # mini apps, gtk3 for QGtk3Theme, geoclue2 for location, libglvnd + mesa
  # for the EGL/GL/OpenGL/GBM dispatchers, libva for hardware video decode).
  runtimeLibsEnv = ''
    export LD_LIBRARY_PATH="${
      lib.makeLibraryPath [
        pkgs.alsa-lib
        pkgs.cairo
        pkgs.dbus
        pkgs.fontconfig
        pkgs.freetype
        pkgs.geoclue2
        pkgs.glib
        pkgs.gtk3
        pkgs.libglvnd
        pkgs.libpulseaudio
        pkgs.libva
        pkgs.libxkbcommon
        pkgs.mesa
        pkgs.pango
        pkgs.pipewire
        pkgs.wayland
        pkgs.webkitgtk_4_1
      ]
    }''${LD_LIBRARY_PATH:+:''${LD_LIBRARY_PATH}}"
  '';

  # Webview runtime: glib-networking's GIO modules give WebKit TLS, and the
  # gsettings schemas (gtk3 + desktop schemas) keep the webview and gtk3 file
  # dialog from erroring on missing settings. Same effect as nixpkgs'
  # gappsWrapperArgs on the old wrapper.
  webviewEnv = ''
    export GIO_EXTRA_MODULES="${pkgs.glib-networking}/lib/gio/modules"
    export XDG_DATA_DIRS="${
      lib.makeSearchPath "share/gsettings-schemas" [
        pkgs.gsettings-desktop-schemas
        pkgs.gtk3
      ]
    }''${XDG_DATA_DIRS:+:''${XDG_DATA_DIRS}}"
  '';

  # Maintain the loader symlink the byte-patched PT_INTERP points at. The
  # kernel resolves it at every exec — including the webview helper the app
  # re-execs later — so it must exist before launch and stay valid. Sticky
  # /tmp: ln -sfn can only replace our own symlink; a foreign file there
  # makes the check below fail loudly instead of running a hijacked loader.
  loaderEnv = ''
    tgld_target="${pkgs.glibc}/lib/ld-linux-x86-64.so.2"
    ln -sfn "$tgld_target" "${tgLoaderPath}"
    if [[ ! -x "${tgLoaderPath}" || "$(readlink -f "${tgLoaderPath}")" != "$tgld_target" ]]; then
      echo "telegram-desktop: ${tgLoaderPath} does not resolve to $tgld_target — remove it and relaunch" >&2
      exit 1
    fi
  '';

  # Common wrapper env — see the blocks above for what each export fixes.
  # Store is read-only, so the built-in updater could never install anything
  # anyway; -noupdate keeps it from asking.
  wrapperEnv = ''
    ${loaderEnv}
    ${nvidiaEglEnv}
    ${fileDialogThemeEnv}
    ${runtimeLibsEnv}
    ${webviewEnv}
    # Session-wide for Kvantum-styled Qt apps, but this build only ships
    # Fusion/Windows styles — the override can never load and just prints a
    # warning on every start.
    unset QT_STYLE_OVERRIDE
    export XKB_CONFIG_ROOT=${pkgs.xkeyboard_config}/share/X11/xkb
    # Mini-apps webview runtime (the webview dlopens webkitgtk-4.1 and the
    # helper inherits this env): a session GDK_BACKEND pin breaks the
    # helper's own backend pinning, and WebKit's DMABUF renderer fails to
    # allocate GBM buffers on the proprietary NVIDIA driver (mini apps render
    # empty) — shared-memory buffers via the UI-process switch instead.
    unset GDK_BACKEND
    export WEBKIT_DISABLE_DMABUF_RENDERER=1
  '';

  telegramDesktop = pkgs.writeShellScriptBin "telegram-desktop" ''
    set -euo pipefail
    ${wrapperEnv}
    # Mark the app as externally updated (see the app-id note in the header):
    # the release build's internal updater is enabled at compile time, which
    # also suffixes its Wayland app-id with an instance hash — the marker
    # flips it back to the plain org.telegram.desktop the niri rules match.
    updaterDir="''${XDG_DATA_HOME:-$HOME/.local/share}/TelegramDesktop/externalupdater.d"
    mkdir -p "$updaterDir"
    printf '%s\n' '${telegramDesktopPkg}/libexec/Telegram' > "$updaterDir/pageton"
    exec ${telegramDesktopPkg}/libexec/Telegram -noupdate "$@"
  '';

  telegramDesktopSecond = pkgs.writeShellScriptBin "telegram-desktop-second" ''
    set -euo pipefail
    workdir="''${XDG_DATA_HOME:-$HOME/.local/share}/TelegramDesktopSecond"
    mkdir -p "$workdir"
    ${wrapperEnv}
    # Same external-updater marker as the primary wrapper, in this workdir
    # (the app checks cWorkingDir()/externalupdater.d at startup).
    updaterDir="$workdir/externalupdater.d"
    mkdir -p "$updaterDir"
    printf '%s\n' '${telegramDesktopPkg}/libexec/Telegram' > "$updaterDir/pageton"
    exec ${telegramDesktopPkg}/libexec/Telegram -noupdate -workdir "$workdir" "$@"
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
