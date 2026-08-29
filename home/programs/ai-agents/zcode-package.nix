{ pkgs, ... }:
let
  version = "3.10.1";

  src = pkgs.fetchurl {
    url = "https://cdn-zcode.z.ai/zcode/electron/releases/${version}/linux-x64/ZCode-${version}-linux-x64.AppImage";
    # NOTE: lib.fakeSha256 is a placeholder. On first build, Nix will fail with
    # "hash mismatch" and print the actual SRI hash. Copy that hash here, then
    # rebuild. Alternatively, run:
    #   nix-prefetch-url "https://cdn-zcode.z.ai/zcode/electron/releases/3.7.5/linux-x64/ZCode-3.7.5-linux-x64.AppImage" | xargs nix hash to-sri --type sha256
    sha256 = "sha256-9T/d0uf3roTimyZgy0oMaHyUmdZbmKdOIifAAWdOI1o=";
  };

  appContents = pkgs.appimageTools.extract {
    pname = "zcode";
    inherit version src;
  };

  zcode = pkgs.appimageTools.wrapType2 {
    pname = "zcode";
    inherit version src;

    extraPkgs = _: [
      pkgs.libsecret # credential/keyring storage
      pkgs.libappindicator-gtk3 # system tray
      pkgs.xdg-utils # open URLs/files from in-app
    ];

    passthru = { inherit appContents; };

    extraInstallCommands = ''
      # Desktop file — rewrite Exec line with required flags
      install -Dm644 ${appContents}/zcode.desktop $out/share/applications/zcode.desktop
      sed -i 's|^Exec=.*|Exec=zcode --no-sandbox --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations %U|' \
        $out/share/applications/zcode.desktop
      # Icons — try standard hicolor layout first
      for size in 16 24 32 48 64 128 256 512 1024; do
        src_path="${appContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/zcode.png"
        if [[ -f "$src_path" ]]; then
          install -Dm644 "$src_path" \
            "$out/share/icons/hicolor/''${size}x''${size}/apps/zcode.png"
        fi
      done

      # Fallback: use bundled icon if hicolor not found
      if ! ls $out/share/icons/hicolor/*/apps/zcode.png >/dev/null 2>&1; then
        for size in 16 24 32 48 64 128 256 512 1024; do
          install -Dm644 \
            ${appContents}/zcode.png \
            $out/share/icons/hicolor/''${size}x''${size}/apps/zcode.png
        done
      fi
    '';
  };
in
[ zcode ]
