{ pkgs, ... }:
let
  windowSwitcher = pkgs.writeScriptBin "window-switcher" ''
    #!/bin/sh
    # Get list of all windows with workspace, class, and title information
    windows=$(hyprctl clients -j | jq -r '.[] | "\(.workspace.id):\(.workspace.name) - \(.class) - \(.title)"')
    selected=$(echo "$windows" | wofi --dmenu --prompt "Switch to window" --width 800)

    if [[ -n "$selected" ]]; then
      # Find the window address and focus it
      address=$(hyprctl clients -j | jq -r --arg sel "$selected" '.[] | select("\(.workspace.id):\(.workspace.name) - \(.class) - \(.title)" == $sel) | .address')
      hyprctl dispatch focuswindow "address:$address"
    fi
  '';
in
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mod,T, exec, uwsm app -- ${pkgs.kitty}/bin/kitty"
      "$mod,B, exec, brave"
      "$shiftMod,HOME, exec,  uwsm app -- ${pkgs.hyprlock}/bin/hyprlock"
      "$mod,X, exec, powermenu"
      "$mod,SPACE, exec, menu"
      "$mod,C, exec, quickmenu"
      "$shiftMod,SPACE, exec, hyprfocus-toggle"
      "$mod, E, exec, ${pkgs.kitty}/bin/kitty -e yazi"
      "$mod, W, exec, ${windowSwitcher}/bin/window-switcher"
      "$shiftMod, R, exec, nautilus"
      "$mod,Q, killactive,"
      "$mod,F, togglefloating,"
      "$mod,F, fullscreen"
      "$mod,h, movefocus, l"
      "$mod,l, movefocus, r"
      "$mod,k, movefocus, u"
      "$mod,j, movefocus, d"
      "$shiftMod, up, focusmonitor, -1"
      "$shiftMod, down, focusmonitor, 1"
      "$shiftMod, left, layoutmsg, addmaster"
      "$shiftMod, right, layoutmsg, removemaster"
      "$mod, P, exec, hyprshot -m window -o ~/Pictures/screenshots"
      "$shiftMod, P, exec, hyprshot -m region -o ~/Pictures/screenshots"
      "$mod, S, togglespecialworkspace, magic"
      "$shiftMod, S, movetoworkspace, special:magic"
      "$mod, A, pin"
      "$shiftMod, grave, workspace, previous"
      "$shiftMod,T, exec, hyprpanel-toggle"
      "$mod,V, exec, clipman pick -t wofi"
      "$shiftMod,E, exec, ${pkgs.wofi-emoji}/bin/wofi-emoji"
      "$mod,F2, exec, night-shift"
      "$mod,F3, exec, night-shift"
      "LAlt,P, exec, ${pkgs.hyprpicker}/bin/hyprpicker --autocopy"
    ]
    ++ (builtins.concatLists (
      builtins.genList (
        i:
        let
          ws = i + 1;
        in
        [
          "$mod,code:1${toString i}, workspace, ${toString ws}"
          "$mod SHIFT,code:1${toString i}, movetoworkspace, ${toString ws}"
        ]
      ) 9
    ));

    bindm = [
      "$mod,mouse:272, movewindow"
      "$mod,R, resizewindow"
      "$mod,Z, movewindow"
    ];

    binde = [
      "$shiftMod,l, resizeactive, 30 0"
      "$shiftMod,h, resizeactive, -30 0"
      "$shiftMod,k, resizeactive, 0 -30"
      "$shiftMod,j, resizeactive, 0 30"
    ];

    bindl = [
      ",XF86AudioMute, exec, sound-toggle"
      ",XF86AudioRaiseVolume, exec, sound-up"
      ",XF86AudioLowerVolume, exec, sound-down"
      ",switch:Lid Switch, exec, ${pkgs.hyprlock}/bin/hyprlock"
    ];
  };
}
