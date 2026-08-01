# Tabby — modern terminal emulator with SSH, serial, and Telnet support.
# https://tabby.sh / https://github.com/Eugeny/tabby
{pkgs, ...}: let
  version = "1.0.235";

  src = pkgs.fetchurl {
    url = "https://github.com/Eugeny/tabby/releases/download/v${version}/tabby-${version}-linux-x64.AppImage";
    # NOTE: lib.fakeSha256 is a placeholder. On first build, Nix will fail with
    # "hash mismatch" and print the actual SRI hash. Copy that hash here, then
    # rebuild. Alternatively, run:
    #   nix-prefetch-url "https://github.com/Eugeny/tabby/releases/download/v1.0.235/tabby-1.0.235-linux-x64.AppImage" | xargs nix hash to-sri --type sha256
    sha256 = "sha256-DKXcAV/l7nhA8rIGhkzDfFL3w2t6c06GU6Oa6KV23O8=";
  };

  appContents = pkgs.appimageTools.extractType2 {
    pname = "tabby";
    inherit version src;
  };

  tabby = pkgs.appimageTools.wrapType2 {
    pname = "tabby";
    inherit version src;

    extraPkgs = _: [
      pkgs.libsecret # credential/keyring storage
      pkgs.xdg-utils # open URLs/files from in-app
    ];

    extraInstallCommands = ''
      # Desktop file — rewrite Exec line with required flags
      install -Dm644 ${appContents}/tabby.desktop $out/share/applications/tabby.desktop
      sed -i 's|^Exec=.*|Exec=tabby --no-sandbox --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations %U|' \
        $out/share/applications/tabby.desktop

      # Icons — try standard hicolor layout first
      for size in 16 24 32 48 64 128 256 512 1024; do
        src_path="${appContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/tabby.png"
        if [[ -f "$src_path" ]]; then
          install -Dm644 "$src_path" \
            "$out/share/icons/hicolor/''${size}x''${size}/apps/tabby.png"
        fi
      done

      # Fallback: use bundled icon if hicolor not found
      if ! ls $out/share/icons/hicolor/*/apps/tabby.png >/dev/null 2>&1; then
        for size in 16 24 32 48 64 128 256 512 1024; do
          install -Dm644 \
            ${appContents}/tabby.png \
            $out/share/icons/hicolor/''${size}x''${size}/apps/tabby.png
        done
      fi
    '';
  };
in [tabby]
