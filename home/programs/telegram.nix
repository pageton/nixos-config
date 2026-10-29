# Telegram Desktop — pageton/tdesktop fork, prebuilt release binary.
#
# Source: the fork's GitHub release tarball
# (https://github.com/pageton/tdesktop/releases — td-setup-linux-x64), pinned
# by tgVersion below. Updates land by bumping tgVersion + the fetchurl hash
# (nix-prefetch-url the new URL, convert to SRI with `nix hash convert`).
# No source build. The tarball's binary comes in two shapes depending on how
# the fork was cut:
#
# - Mostly-static (up to 7.2.x): Qt, tgcalls, lib_ui, ffmpeg baked in; only
#   dlopen'd runtimes come from the wrapper env below.
# - Dev-shell build (7.3.3+): dynamically linked against the nix store
#   closure of the machine that cut the release — PT_INTERP and DT_RUNPATH
#   embed ~50 absolute /nix/store paths at release time. That makes the
#   artifact host-specific: it only runs where those paths exist. Garbage
#   collection keeps them only via the release machine's own roots (the
#   tdesktop project profile pins its dev-shell closure) — reference
#   scanning does not cover foreign paths. Releases are cut from
#   ~/Projects/tdesktop on this machine, so that holds for every release
#   consumed here; elsewhere the wrappers catch the failed exec and say
#   so, and the loader names any missing library.
#
# Two non-obvious constraints, both worked around in this file:
#
# 1. patchelf is unusable. Any --set-interpreter/--set-rpath rewrite of this
#    multi-segment binary corrupts it — the patched binary jumps into its own
#    ELF headers during init_array (SIGILL/SIGSEGV, verified). Instead the
#    PT_INTERP payload — the stock "/lib64/ld-linux-x86-64.so.2" on the old
#    static releases, the release machine's store loader on dev-shell builds
#    — is overwritten IN PLACE with a shorter path (tgLoaderPath) and
#    NUL-padded: pure string rewrite, no header/segment/size changes. The
#    wrapper keeps a symlink at tgLoaderPath pointing at the pinned nix
#    glibc loader, so the kernel can exec the binary directly and THIS
#    machine's glibc always drives the process (forward-compatible with
#    every lib in the release closure).
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
  tgVersion = "7.3.3";

  # Short path the PT_INTERP payload is byte-patched to (must stay shorter
  # than the stock 27-byte "/lib64/ld-linux-x86-64.so.2"). The wrapper
  # creates/verifies a symlink here on every launch — see the header.
  tgLoaderPath = "/tmp/tgld";

  telegramDesktopPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "pageton-desktop";
    version = tgVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/pageton/tdesktop/releases/download/v${tgVersion}/td-setup-linux-x64-${tgVersion}.tar.xz";
      hash = "sha256-JXDQ6xfLPD9YJcVysEKBg0kfnmXgfgQcv8aNLOtuR6A=";
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

      # Rewrite PT_INTERP in place with tgLoaderPath, whatever it currently
      # holds: static releases carry the stock "/lib64/ld-linux-x86-64.so.2",
      # dev-shell releases the release machine's store loader (currently
      # glibc 2.42 while this config's libs are built against 2.43 — running
      # under the older loader aborts with GLIBC_2.43-not-found). The payload
      # is found via the ELF program headers and overwritten with a shorter
      # NUL-padded string — no header/segment/size changes (patchelf is
      # unusable on this binary; see the header). The wrapper keeps the
      # /tmp/tgld symlink pointing at THIS machine's glibc loader, so the
      # newest glibc always drives the process and every lib (release
      # closure included) sees a forward-compatible loader.
      binary=$out/libexec/Telegram
      rd() { od -An -tu$2 -j$(( $1 )) -N$2 "$binary" | tr -d ' '; }
      phoff=$(rd 32 8)
      phentsize=$(rd 54 2)
      phnum=$(rd 56 2)
      interpOff=-1
      for (( i = 0; i < phnum; i++ )); do
        off=$(( phoff + i * phentsize ))
        if [[ $(rd $off 4) -eq 3 ]]; then
          interpOff=$(rd $(( off + 8 )) 8)
          break
        fi
      done
      (( interpOff >= 0 )) || { echo "PT_INTERP not found" >&2; exit 1; }
      len=0
      while (( $(rd $(( interpOff + len )) 1) != 0 )); do len=$(( len + 1 )); done
      to='${tgLoaderPath}'
      (( ''${#to} <= len )) \
        || { echo "tgLoaderPath (''${#to} bytes) does not fit interp payload ($len bytes)" >&2; exit 1; }
      printf '%s' "$to" | dd of="$binary" bs=1 seek="$interpOff" conv=notrunc status=none
      dd if=/dev/zero bs=1 count=$(( len - ''${#to} )) \
        | dd of="$binary" bs=1 seek=$(( interpOff + ''${#to} )) conv=notrunc status=none

      # Dev-shell releases embed their store closure in PT_INTERP/RUNPATH.
      # Manifest it here for the wrappers: nix's reference scanner does not
      # register foreign store paths that aren't derivation inputs (verified,
      # so gc-safety relies on the release machine's own roots — the tdesktop
      # project profile pins this closure), and the loader ignores the
      # embedded DT_RUNPATH, so the wrappers turn this list into
      # LD_LIBRARY_PATH entries to resolve every DT_NEEDED.
      grep -aoE '/nix/store/[a-z0-9]{32}-[a-zA-Z0-9.+_-]+' "$binary" \
        | sort -u > $out/libexec/tg-store-closure

      runHook postInstall
    '';
  };

  # NVIDIA EGL fix for mini apps (WebKitGTK webview) — see
  # home/core/desktop-entries.nix for the rationale.
  nvidiaEglEnv = ''
    export GBM_BACKEND=nvidia-drm
    # The NVIDIA EGL loader only searches /etc/egl and /usr/share/egl for the
    # external-platform configs (libnvidia-egl-wayland: the Wayland/GBM/X11
    # EGL platforms) — point it at the driver bundle or EGL falls back to
    # llvmpipe under native Wayland (QEGLPlatformContext/QRhi errors). Same
    # dir-form overrides the tdesktop dev shell verified with eglinfo.
    export __EGL_VENDOR_LIBRARY_DIRS=/run/opengl-driver/share/glvnd/egl_vendor.d
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

  # NixOS has no ld.so.cache and the binary is unpatched (see header). The
  # static builds resolved EVERYTHING from here; dev-shell builds get their
  # DT_NEEDED from the embedded RUNPATH, where LD_LIBRARY_PATH (searched
  # first) shadows overlapping sonames with the same nixpkgs versions the
  # static builds used — one proven env for both shapes. gcc.cc.lib keeps
  # a single (ours, newest) libstdc++ ahead of the release closure's.
  # Uniquely supplied
  # either way: the .note.dlopen metadata (pipewire/pulseaudio/alsa backends
  # + dbus), and plain dlopens (wayland + xkbcommon at startup, webkitgtk for
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
        pkgs.gcc.cc.lib
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

  # Dev-shell releases carry their dependency closure as embedded store
  # paths, and the loader ignores their DT_RUNPATH (observed: exec dies on
  # the first DT_NEEDED no matter what RUNPATH lists). The package manifests
  # those paths in tg-store-closure (see installPhase) — append their /lib
  # dirs here so every DT_NEEDED resolves through LD_LIBRARY_PATH instead.
  # Nonexistent dirs are skipped by the loader; static releases ship an
  # empty manifest, making this a no-op for them.
  closureLibsEnv = ''
    closureList='${telegramDesktopPkg}/libexec/tg-store-closure'
    if [[ -r "$closureList" ]]; then
      while IFS= read -r p; do
        # The loader must always pair with its own libc — letting the
        # release closure's older glibc shadow it breaks every lib built
        # against a newer one (GLIBC_2.4x-not-found).
        if [[ $p != *-glibc-* && -d "$p/lib" ]]; then
          export LD_LIBRARY_PATH="''${LD_LIBRARY_PATH:+''${LD_LIBRARY_PATH}:}$p/lib"
        fi
      done < "$closureList"
    fi
  '';

  # Dev-shell releases ship no Qt plugin tree: the fork's build generates an
  # app-local qt.conf + qt-plugins next to the binary, but the release
  # tarball carries only the bare binary — without it the app segfaults on
  # emoji loading (the WebP codec lives in qtimageformats, outside qtbase;
  # the project's dev-shell notes document this exact crash). Point
  # QT_PLUGIN_PATH at the release closure's Qt plugin dirs, plus a
  # qtimageformats whose version matches the closure's qtbase exactly — Qt
  # version-checks plugins and the WebP one is load-bearing. That package
  # comes from the project's dev shell (not this flake's nixpkgs, whose Qt
  # has already moved on) and is store-rooted by the project profile like
  # the rest of the closure.
  qtPluginsEnv = ''
    qtPluginList='${telegramDesktopPkg}/libexec/tg-store-closure'
    QTP=""
    qtVersion=""
    webpPlugins=""
    if [[ -r "$qtPluginList" ]]; then
      while IFS= read -r p; do
        if [[ $p == *-qt* && -d "$p/lib/qt-6/plugins" ]]; then
          QTP+=":$p/lib/qt-6/plugins"
          case $p in *-qtbase-*) qtVersion="''${p##*-qtbase-}" ;; esac
        fi
      done < "$qtPluginList"
    fi
    if [[ -n "$qtVersion" ]]; then
      for d in /nix/store/*-qtimageformats-"$qtVersion"; do
        if [[ -d "$d/lib/qt-6/plugins/imageformats" ]]; then
          webpPlugins="$d/lib/qt-6/plugins"
          QTP+=":$webpPlugins"
          break
        fi
      done
    fi
    export QT_PLUGIN_PATH="''${QTP#:}''${QT_PLUGIN_PATH:+:''${QT_PLUGIN_PATH}}"
    if [[ -z "$webpPlugins" ]] || ! ls "$webpPlugins"/imageformats/libqwebp* >/dev/null 2>&1; then
      echo "telegram-desktop: no qtimageformats-$qtVersion WebP plugin found in the store — the release segfaults on emoji loading without it (keep the tdesktop project dev shell built)" >&2
      exit 1
    fi
  '';

  # GSettings schema dirs in the deep form glib's schema-source scan
  # resolves (<entry>/glib-2.0/schemas/gschemas.compiled). This flake's
  # glib (2.88+) no longer carries the old nixpkgs patch that also matched
  # <entry>/gsettings-schemas/*/glib-2.0/schemas, so "share"-level
  # XDG_DATA_DIRS entries match nothing: g_settings_new aborts with the
  # fatal GLib-GIO-ERROR "No GSettings schemas" (main app via the gtk3 file
  # dialog) and WebKitWebProcess dies of the same abort, surfacing as
  # WebView-CRITICAL "Web process terminated: 0" (verified with
  # g_settings_new + MiniBrowser against both forms). Subdirs are enumerated
  # at eval time so version-named entries need no pinning; packages without
  # schemas contribute nothing.
  gsettingsSchemaDirs = lib.concatStringsSep ":" (
    lib.flatten (
      map
        (
          p:
          let
            d = "${p}/share/gsettings-schemas";
          in
          lib.optionals (builtins.pathExists d) (map (n: "${d}/${n}") (lib.attrNames (builtins.readDir d)))
        )
        [
          pkgs.gsettings-desktop-schemas
          pkgs.gtk3
        ]
    )
  );

  # Webview runtime: glib-networking's GIO modules give WebKit TLS. The
  # makeSearchPath "share" entries cover mime/icons; the gsettings schemas
  # (desktop schemas + gtk3's own) ride along ONLY as the deep entries from
  # gsettingsSchemaDirs — with "share"-level entries alone every GSettings
  # consumer in the process tree dies on a NULL schema source (see above).
  webviewEnv = ''
    export GIO_EXTRA_MODULES="${pkgs.glib-networking}/lib/gio/modules"
    export XDG_DATA_DIRS="${
      lib.makeSearchPath "share" [
        pkgs.glib-networking
        pkgs.gsettings-desktop-schemas
        pkgs.gtk3
        pkgs.shared-mime-info
        pkgs.webkitgtk_4_1
      ]
    }:${gsettingsSchemaDirs}''${XDG_DATA_DIRS:+:''${XDG_DATA_DIRS}}"
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
    ${closureLibsEnv}
    ${qtPluginsEnv}
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
    # Dev-shell releases only exec on the machine that cut them (their
    # PT_INTERP/RUNPATH embed that host's store closure) — turn the bare
    # kernel ENOENT into an explanation. Without execfail a failed exec
    # kills the script before anything can be said.
    shopt -s execfail
    exec ${telegramDesktopPkg}/libexec/Telegram -noupdate "$@"
    status=$?
    if (( status == 127 )); then
      echo "telegram-desktop: pageton binary failed to exec — dev-shell releases embed the release host's /nix/store closure and only run there" >&2
    fi
    exit "$status"
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
    shopt -s execfail
    exec ${telegramDesktopPkg}/libexec/Telegram -noupdate -workdir "$workdir" "$@"
    status=$?
    if (( status == 127 )); then
      echo "telegram-desktop-second: pageton binary failed to exec — dev-shell releases embed the release host's /nix/store closure and only run there" >&2
    fi
    exit "$status"
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
