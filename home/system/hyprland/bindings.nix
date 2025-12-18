{pkgs, ...}: {
  wayland.windowManager.hyprland.settings = {
    bind =
      [
        "$mod, Return, exec, uwsm app -- ${pkgs.alacritty}/bin/alacritty"
        "$mod, T, exec, uwsm app -- ${pkgs.alacritty}/bin/alacritty --class=scratchpad"
        "$mod,B, exec, brave"
        "$shiftMod,HOME, exec,  uwsm app -- ${pkgs.hyprlock}/bin/hyprlock"
        "$mod,X, exec, powermenu"
        "$mod,SPACE, exec, vicinae toggle"
        "$mod,C, exec, quickmenu"
        "$shiftMod,SPACE, exec, hyprfocus-toggle"
        "$mod, E, exec, ${pkgs.alacritty}/bin/alacritty -e yazi"
        "$mod, W, exec, window-switcher"
        "$shiftMod, R, exec, dolphin"
        "$mod,Q, killactive,"
        "$mod,F, togglefloating,"
        "$shiftMod, F, fullscreen"
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
        "$mod,V, exec, clipboard"
        "$shiftMod,E, exec, pgrep wofi >/dev/null 2>&1 && killall wofi || ${pkgs.wofi-emoji}/bin/wofi-emoji"
        "$mod,F2, exec, night-shift"
        "$mod,F3, exec, night-shift"
        # "LAlt,P, exec, ${pkgs.hyprpicker}/bin/hyprpicker --autocopy"
        "$ctrlMod, L, exec, hyprctl keyword general:layout dwindle" # Switch to dwindle layout
        "$ctrlMod SHIFT, L, exec, hyprctl keyword general:layout master" # Switch to master layout
      ]
      ++ (builtins.concatLists (
        builtins.genList (
          i: let
            ws = i + 1;
          in [
            "$mod,code:1${toString i}, workspace, ${toString ws}"
            "$shiftMod ,code:1${toString i}, movetoworkspace, ${toString ws}"
          ]
        )
        9
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

    binded = [
      "$ctrlMod, h, Move active window to the left, exec, $moveactivewindow -30 0 || hyprctl dispatch movewindow l"
      "$ctrlMod, l, Move active window to the right, exec, $moveactivewindow 30 0 || hyprctl dispatch movewindow r"
      "$ctrlMod, k, Move active window up, exec, $moveactivewindow 0 -30 || hyprctl dispatch movewindow u"
      "$ctrlMod, j, Move active window down, exec, $moveactivewindow 0 30 || hyprctl dispatch movewindow d"
    ];

    bindl = [
      ",XF86AudioMute, exec, sound-toggle"
      ",XF86AudioRaiseVolume, exec, sound-up"
      ",XF86AudioLowerVolume, exec, sound-down"
      ",switch:Lid Switch, exec, ${pkgs.hyprlock}/bin/hyprlock"
    ];
  };
}
