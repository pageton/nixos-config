{pkgs, ...}: let
  version = "0.0.28";

  src = pkgs.fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    # NOTE: lib.fakeSha256 is a placeholder. On first build, Nix will fail with
    # "hash mismatch" and print the actual SRI hash. Copy that hash here, then
    # rebuild. Alternatively, run:
    #   nix-prefetch-url "https://github.com/pingdotgg/t3code/releases/download/v0.0.28/T3-Code-0.0.28-x86_64.AppImage" | xargs nix hash to-sri --type sha256
    sha256 = "sha256-+mBp+wPrJRV/HpaimQHcqBuwqZcPWTbKJVNCVW7ELgo=";
  };

  appContents = pkgs.appimageTools.extractType2 {
    pname = "t3code";
    inherit version src;
  };

  t3code = pkgs.appimageTools.wrapType2 {
    pname = "t3code";
    inherit version src;

    extraPkgs = _: [
      pkgs.libsecret # credential/keyring storage
    ];

    extraInstallCommands = ''
      # Desktop file — rewrite Exec line
      install -Dm644 ${appContents}/t3code.desktop $out/share/applications/t3code.desktop
      sed -i 's|^Exec=.*|Exec=t3code --no-sandbox --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations %U|' \
        $out/share/applications/t3code.desktop

      # Icons
      for size in 16 24 32 48 64 128 256 512 1024; do
        src_path="${appContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/t3code.png"
        if [[ -f "$src_path" ]]; then
          install -Dm644 "$src_path" \
            "$out/share/icons/hicolor/''${size}x''${size}/apps/t3code.png"
        fi
      done

      # Fallback: use bundled icon
      if ! ls $out/share/icons/hicolor/*/apps/t3code.png >/dev/null 2>&1; then
        for size in 16 24 32 48 64 128 256 512 1024; do
          install -Dm644 \
            ${appContents}/t3code.png \
            $out/share/icons/hicolor/''${size}x''${size}/apps/t3code.png
        done
      fi
    '';
  };
in [t3code]
