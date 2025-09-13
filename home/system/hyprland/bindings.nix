{ pkgs, ... }:
{
  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mod,T, exec, uwsm app -- ${pkgs.kitty}/bin/kitty"
      "$mod,B, exec, brave"
      "$shiftMod,L, exec,  uwsm app -- ${pkgs.hyprlock}/bin/hyprlock"
      "$mod,X, exec, powermenu"
      "$mod,SPACE, exec, menu"
      "$mod,C, exec, quickmenu"
      "$shiftMod,SPACE, exec, hyprfocus-toggle"
      "$mod, E, exec, ${pkgs.kitty}/bin/kitty -e yazi"
      "$shiftMod, R, exec, nautilus"
      "$mod,Q, killactive,"
      "$mod,W, togglefloating,"
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
      "$mod,V, exec, clipboard"
      "$shiftMod,E, exec, ${pkgs.wofi-emoji}/bin/wofi-emoji"
      "$mod,F2, exec, night-shift"
      "$mod,F3, exec, night-shift"
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
      "$mod,X, resizewindow"
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
