# T3 Code - AI-powered code editor by pingdotgg
# https://github.com/pingdotgg/t3code
#
# To update to the latest version:
# 1. Run: curl -sL https://api.github.com/repos/pingdotgg/t3code/releases/latest | jq -r '.tag_name'
# 2. Update the `version` variable below
# 3. Run: nix store prefetch-file --json --hash-type sha256 \
#    "https://github.com/pingdotgg/t3code/releases/download/v<VERSION>/T3-Code-<VERSION>-x86_64.AppImage"
# 4. Update the `hash` variable with the output
{ lib, pkgs, ... }:
let
  version = "0.0.17";
  hash = "sha256-uS+o1nRA3R7hn9BaomrdsGVC8UcpPFFRG3a1qGVrs8w=";

  pname = "t3-code";

  src = pkgs.fetchurl {
    name = "${pname}-${version}-x86_64.AppImage";
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    inherit hash;
  };

  extracted = pkgs.appimageTools.extractType2 { inherit pname version src; };

  t3code-appimage = pkgs.appimageTools.wrapType2 {
    inherit pname version src;
    extraPkgs =
      pkgs: with pkgs; [
        libsecret
        libnotify
      ];
    extraInstallCommands = ''
      # Copy embedded icons from the extracted AppImage tree.
      for size in 16 32 48 64 128 256 512; do
        if [ -f "${extracted}/usr/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png" ]; then
          install -Dm644 "${extracted}/usr/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png" \
            $out/share/icons/hicolor/''${size}x''${size}/apps/${pname}.png
        fi
      done

      # Fallback: use the first embedded PNG if the expected icon layout changes.
      if ! find "$out/share/icons/hicolor" -path '*/apps/*.png' -print -quit | grep -q .; then
        icon=$(find "${extracted}" -name "*.png" -type f | head -1)
        if [ -n "$icon" ]; then
          install -Dm644 "$icon" $out/share/icons/hicolor/256x256/apps/${pname}.png
        fi
      fi
    '';
  };
in
{
  home.packages = [ t3code-appimage ];
}
