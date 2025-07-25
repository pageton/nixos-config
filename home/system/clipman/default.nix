{ pkgs, ... }:
let
  clipboard-clear = pkgs.writeShellScriptBin "clipboard-clear" ''
    clipman clear --all
  '';

  clipboard = pkgs.writeShellScriptBin "clipboard" ''
    clipman pick --tool=wofi
  '';

in
{
  wayland.windowManager.hyprland.settings.exec-once = [
    "${clipboard-clear}"
    "wl-paste -t text --watch clipman store"
  ];
  home.packages = [
    clipboard
    clipboard-clear
  ];
  services.clipman.enable = true;
}
