{
  config,
  lib,
  hostname,
  ...
}: let
  inherit
    (config.theme)
    border-size
    gaps-in
    gaps-out
    active-opacity
    inactive-opacity
    rounding
    blur
    ;
  background = "rgb(" + config.lib.stylix.colors.base00 + ")";
  isThinkpad = hostname == "thinkpad";
in {
  imports = [
    ./animations.nix
    ./bindings.nix
    ./polkitagent.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd = {
      enable = true;
      variables = ["--all"];
    };
    package = null;
    portalPackage = null;

    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";
      "$ctrlMod" = "SUPER_CTRL";

      "$moveactivewindow" = "grep -q 'true' <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive";

      exec-once = [
        "dbus-update-activation-environment --systemd --all &"
        "systemctl --user start glance"
        "systemctl --user enable --now hyprpaper.service &"
        "swayosd-server &"
        "wl-paste --type text --watch cliphist store" # Clipboard manager for text
        "wl-paste --type image --watch cliphist store" # Clipboard manager for images
      ];

      monitor = ",preferred,auto,1";

      env = [
        "XCURSOR_SIZE,${
          if isThinkpad
          then "20"
          else "24"
        }"
        "HYPRCURSOR_SIZE,${
          if isThinkpad
          then "20"
          else "24"
        }"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "MOZ_ENABLE_WAYLAND,1"
        "ANKI_WAYLAND,1"
        "DISABLE_QT5_COMPAT,0"
        "NIXOS_OZONE_WL,1"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "QT_AUTO_SCREEN_SCALE_FACTOR,1"
        "QT_QPA_PLATFORM=wayland,xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "__GL_GSYNC_ALLOWED,0"
        "__GL_VRR_ALLOWED,0"
        "DISABLE_QT5_COMPAT,0"
        "DIRENV_LOG_FORMAT,"
        "WLR_DRM_NO_ATOMIC,1"
        "WLR_BACKEND,vulkan"
        "WLR_RENDERER,vulkan"
        "WLR_NO_HARDWARE_CURSORS,1"
        "SDL_VIDEODRIVER,wayland"
        "CLUTTER_BACKEND,wayland"
      ];

      cursor = {
        no_hardware_cursors = true;
      };

      general = {
        resize_on_border = true;
        gaps_in = gaps-in;
        gaps_out = gaps-out;
        border_size = border-size;
        layout = "master";
        "col.inactive_border" = lib.mkForce background;
        allow_tearing = false;
      };

      decoration = {
        active_opacity = active-opacity;
        inactive_opacity = inactive-opacity;
        inherit rounding;
        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
        };
        blur = {
          enabled =
            if blur
            then "true"
            else "false";
          ignore_opacity = false;
          new_optimizations = true;
          xray = false;
          size = 18;
          passes = 2;
        };
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        smart_split = false;
        smart_resizing = true;
        force_split = 0; # 0 = split follows mouse, 1 = always split to the right/bottom, 2 = always split to the left/top
        default_split_ratio = 1.0;
        use_active_for_splits = true;
        split_width_multiplier = 1.0;
      };

      master = {
        new_status = "slave";
        new_on_top = true;
        mfact = 0.55;
        orientation = "left"; # Default to vertical split (master on left)
        smart_resizing = true;
        drop_at_cursor = true;
      };

      misc = {
        vfr = true;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        disable_autoreload = true;
        focus_on_activate = true;
        on_focus_under_fullscreen = 1; # Replaces master:inherit_fullscreen (0=focus,1=prevent,2=allow)
      };

      windowrule2 = [
        "float, tag:modal"
        "pin, tag:modal"
        "center, tag:modal"
        "float, title:^(Media viewer)$"
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "pin,class:^(showmethekey-gtk)$" # Pin window to stay visible
        "idleinhibit focus, class:^(mpv|.+exe|celluloid)$"
        "idleinhibit focus, class:^(zen|brave-browser)$, title:^(.*YouTube.*)$"
        "opacity 0.95, class:(zen)" # Browser transparency
        "idleinhibit fullscreen, class:^(zen|brave-browser)$"
        "dimaround, class:^(gcr-prompter)$"
        "dimaround, class:^(xdg-desktop-portal-gtk)$"
        "dimaround, class:^(polkit-gnome-authentication-agent-1)$"
        "dimaround, class:^(brave-browser)$, title:^(File Upload)$"

        # Special workspace rules
        "bordersize 0, floating:0, onworkspace:w[t1]" # No borders on special workspace

        # General window behavior
        "suppressevent maximize, class:.*" # Disable maximize for all windows
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"

        # XWayland video bridge (fixes screen sharing)
        "opacity 0.0 override, class:^(xwaylandvideobridge)$"
        "noanim, class:^(xwaylandvideobridge)$"
        "noinitialfocus, class:^(xwaylandvideobridge)$"
        "maxsize 1 1, class:^(xwaylandvideobridge)$"
        "noblur, class:^(xwaylandvideobridge)$"
        "nofocus, class:^(xwaylandvideobridge)$"

        # Scratchpad configuration
        "float, title:^(scratchpad)$"
        "float,class:^(scratchpad)$"
        "noanim,class:^(scratchpad)$"
        "pin,class:^(scratchpad)$"
        "size 60% 60%,class:^(scratchpad)$"
        "center,class:^(scratchpad)$"

        # Telegram Mini Apps
        "float, class:^(org.telegram.desktop)$, title:^(Mini App:.*)$"
        "center, class:^(org.telegram.desktop)$, title:^(Mini App:.*)$"
        "size 473 876, class:^(org.telegram.desktop)$, title:^(Mini App:.*)$"

        # Scrcpy
        "float,class:^(.*scrcpy.*)"
        "size 503 1119,class:^(.*scrcpy.*)"

        "opacity 0.95 0.85, class:^(Alacritty|kitty|foot|Ghostty)$" # Terminal transparency
        "rounding 0, xwayland:1"

        "opacity 1.0 1.0, class:Waydroid"
      ];

      layerrule = [];

      input = {
        kb_layout = "us,ara";
        kb_variant = "";
        kb_model = "";
        kb_options = "grp:caps_toggle";
        kb_rules = "";
        follow_mouse = true;
        sensitivity = 0.5;
        repeat_delay = 300;
        repeat_rate = 30;

        touchpad = {
          natural_scroll = false;
          disable_while_typing = true;
          clickfinger_behavior = true; # Enable tap-to-click
          tap-to-click = true; # Enable tap-to-click
        };
      };
    };
  };
}
