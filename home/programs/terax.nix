# Terax AI editor — installed via AppImage.
{ pkgs, ... }:
let
  version = "0.6.6";

  src = pkgs.fetchurl {
    url = "https://github.com/crynta/terax-ai/releases/download/v${version}/Terax_${version}_amd64.AppImage";
    hash = "sha256-4Ns4tz/SjExIKUTP/Uo74JwyE5fEBRF9pHDzAjzDVL4=";
  };
in
{
  home.packages = [
    (pkgs.runCommand "terax-${version}" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      mkdir -p $out/bin
      makeWrapper ${pkgs.appimage-run}/bin/appimage-run $out/bin/terax \
        --add-flags ${src}
    '')
  ];
}
