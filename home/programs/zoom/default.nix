{ pkgs, ... }:
let
  zoomLive = pkgs.writeShellScriptBin "zoom-live" ''
    exec brave --new-window "https://app.zoom.us/wc/" "$@"
  '';
in
{
  home.packages = with pkgs; [
    zoom-us
    zoomLive
  ];
}
