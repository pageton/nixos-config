# Package the JetBrains ThinkRail desktop app (Electrobun/Bun + WebKitGTK)
# from the stable v0.2.0 GitHub release.
#
# The `thinkrail-desktop-linux-x64.tar.gz` asset is only a wrapper: it ships a
# Zig installer that embeds the app payload. Upstream publishes the very same
# payload as a standalone archive (`stable-linux-x64-ThinkRail-<version>.tar.zst`)
# whose hash is pinned in the release SHA256SUMS manifest — this is what the
# installer unpacks into ~/.local/share, so fetch it directly and install the
# tree declaratively instead of running the installer at build time.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  zstd,
  git,
  # Linux desktop runtime required by the bundled native wrapper
  # (WebKitGTK renderer, GTK3 UI, tray icon, SVG assets).
  gtk3,
  webkitgtk_4_1,
  libayatana-appindicator,
  librsvg,
  gsettings-desktop-schemas,
  glib-networking,
  dconf,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "thinkrail";
  version = "0.2.0";

  src = fetchurl {
    url = "https://github.com/JetBrains/thinkrail/releases/download/v${finalAttrs.version}/stable-linux-x64-ThinkRail-${finalAttrs.version}.tar.zst";
    hash = "sha256-QJuN/aI8Cr5ScTG+/3RyMvW3qR3F34tFrTHShD/yjg0=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    zstd
  ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
    libayatana-appindicator
    librsvg
    # libNativeWrapper.so links against libstdc++/libgcc_s.
    stdenv.cc.cc.lib
  ];

  # No build: install the upstream tree as-is. The main process resolves its
  # resources (Resources/, version.json, libElectrobunCore.so) relative to the
  # bun executable path, so the bin/ + Resources/ layout must stay intact.
  installPhase = ''
    runHook preInstall

    appDir="$out/share/thinkrail"
    mkdir -p "$appDir" "$out/bin" "$out/share/applications"
    # sourceRoot is the archive's top-level ThinkRail/ directory.
    cp -a . "$appDir/"
    chmod -R u+w "$appDir"

    # Upstream desktop entry; point it at the wrapped launcher and a themed
    # icon instead of the adjacent-file Exec=launcher/Icon=appIcon.
    install -Dm644 \
      "$appDir/Resources/appIcon.png" \
      "$out/share/icons/hicolor/512x512/apps/thinkrail.png"
    substitute ThinkRail.desktop "$out/share/applications/thinkrail.desktop" \
      --replace-fail "Exec=launcher" "Exec=thinkrail" \
      --replace-fail "Icon=appIcon" "Icon=thinkrail"

    # The launcher preflight-dlopens the desktop stack by soname and then
    # spawns bun with Resources/main.js, so keep the libraries visible even
    # where RPATHs do not apply (bare dlopen lookups).
    makeWrapper "$appDir/bin/launcher" "$out/bin/thinkrail" \
      --prefix PATH : ${lib.makeBinPath [ git ]} \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          gtk3
          webkitgtk_4_1
          libayatana-appindicator
          librsvg
        ]
      } \
      --prefix XDG_DATA_DIRS : ${
        lib.makeSearchPath "share" [
          gtk3
          gsettings-desktop-schemas
        ]
      } \
      --prefix GIO_EXTRA_MODULES : ${
        lib.makeSearchPath "lib/gio/modules" [
          glib-networking
          dconf.lib
        ]
      } \
      --set GDK_PIXBUF_MODULE_FILE ${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache \
      --set-default THINKRAIL_NO_ANALYTICS 1

    runHook postInstall
  '';

  meta = {
    description = "JetBrains incubator desktop IDE built around the pi coding agent";
    homepage = "https://github.com/JetBrains/thinkrail";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    mainProgram = "thinkrail";
  };
})
