{ config, lib, ... }:
let
  border-size = config.theme.border-size;
  gaps-in = config.theme.gaps-in;
  gaps-out = config.theme.gaps-out;
  active-opacity = config.theme.active-opacity;
  inactive-opacity = config.theme.inactive-opacity;
  rounding = config.theme.rounding;
  blur = config.theme.blur;
  background = "rgb(" + config.lib.stylix.colors.base00 + ")";
  hostname = builtins.getEnv "HOSTNAME";
  isThinkpad = hostname == "thinkpad";
in
{

  imports = [
    ./animations.nix
    ./bindings.nix
    ./polkitagent.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd = {
      enable = false;
      variables = [ "--all" ];
    };
    package = null;
    portalPackage = null;

    settings = {
      "$mod" = "SUPER";
      "$shiftMod" = "SUPER_SHIFT";
      "$ctrlMod" = "SUPER_CTRL";

      "$moveactivewindow" =
        "grep -q 'true' <<< $(hyprctl activewindow -j | jq -r .floating) && hyprctl dispatch moveactive";

      exec-once = [
        "dbus-update-activation-environment --systemd --all &"
        "systemctl --user enable --now hyprpaper.service &"
        "systemctl --user enable --now nextcloud-client.service  &"
        "wl-paste -t text --watch clipman store &" # Primary clipboard
        "wl-paste --watch -p clipman store -P ~/.local/share/clipman-primary.json &"
        "wl-paste --type text --watch cliphist store &" # Clipboard manager for text
        "wl-paste --type image --watch cliphist store &" # Clipboard manager for images
      ];

      monitor = ",preferred,auto,1";

      env = [
        "XCURSOR_SIZE,${if isThinkpad then "20" else "24"}"
        "HYPRCURSOR_SIZE,${if isThinkpad then "20" else "24"}"
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
      };

      decoration = {
        active_opacity = active-opacity;
        inactive_opacity = inactive-opacity;
        rounding = rounding;
        shadow = {
          enabled = true;
          range = 20;
          render_power = 3;
        };
        blur = {
          enabled = if blur then "true" else "false";
          size = 18;
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
        inherit_fullscreen = true;
        smart_resizing = true;
        drop_at_cursor = true;
      };

      misc = {
        vfr = true;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        disable_autoreload = true;
        focus_on_activate = true;
        new_window_takes_over_fullscreen = 2;
      };

      windowrulev2 = [
        "float, tag:modal"
        "pin, tag:modal"
        "center, tag:modal"
        "float, title:^(Media viewer)$"
        "float, title:^(Picture-in-Picture)$"
        "pin, title:^(Picture-in-Picture)$"
        "pin,class:^(showmethekey-gtk)$" # Pin window to stay visible
        "idleinhibit focus, class:^(mpv|.+exe|celluloid)$"
        "idleinhibit focus, class:^(brave-browser)$, title:^(.*YouTube.*)$"
        "idleinhibit fullscreen, class:^(brave-browser)$"
        "dimaround, class:^(gcr-prompter)$"
        "dimaround, class:^(xdg-desktop-portal-gtk)$"
        "dimaround, class:^(polkit-gnome-authentication-agent-1)$"
        "dimaround, class:^(brave-browser)$, title:^(File Upload)$"
        "opacity 0.95 0.85, class:^(Alacritty|kitty|foot)$" # Terminal transparency
        "rounding 0, xwayland:1"
      ];

      layerrule = [
        "noanim, launcher"
        "noanim, ^ags-.*"
      ];

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
