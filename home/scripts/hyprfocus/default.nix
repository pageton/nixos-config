{
  lib,
  hostname,
  pkgs,
  ...
}: let
  hyprfocus-on = pkgs.writeShellScriptBin "hyprfocus-on" ''
    hyprpanel-hide

    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0;\
        keyword decoration:inactive_opacity 1;\
        keyword decoration:active_opacity 1"

    echo "1" > /tmp/hyprfocus
  '';

  hyprfocus-off = pkgs.writeShellScriptBin "hyprfocus-off" ''
    hyprctl reload
    hyprpanel-show
    rm /tmp/hyprfocus
  '';

  hyprfocus-toggle = pkgs.writeShellScriptBin "hyprfocus-toggle" ''
    if [ -f /tmp/hyprfocus ]; then
      hyprfocus-off
    else
      hyprfocus-on
    fi
  '';
in {
  home.packages = lib.mkIf (hostname != "server") [
    hyprfocus-on
    hyprfocus-off
    hyprfocus-toggle
  ];
}
