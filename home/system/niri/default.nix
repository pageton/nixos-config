# Niri scrollable-tiling Wayland compositor — Home Manager configuration.
{
  config,
  hostname,
  ...
}: let
  inherit
    (config.theme)
    border-size
    gaps-in
    active-opacity
    inactive-opacity
    rounding
    ;
  inherit (config.lib.stylix) colors;
  accent = "#${colors.base0D}";
  accentAlt = "#${colors.base0E}";
  inactive = "#${colors.base03}";
  isThinkpad = hostname == "thinkpad";
in {
  imports = [
    ./animations.nix
    ./bindings.nix
  ];

  programs.niri = {
    settings = {
      prefer-no-csd = true;
      screenshot-path = "~/Pictures/Screenshots/screenshot-%Y-%m-%d-%H-%M-%S.png";
      hotkey-overlay.skip-at-startup = true;

      # ── Input ─────────────────────────────────────────────────
      input = {
        keyboard = {
          xkb = {
            layout = "us,ara";
            options = "grp:caps_toggle";
          };
          repeat-delay = 300;
          repeat-rate = 30;
        };

        touchpad = {
          tap = true;
          dwt = true;
          natural-scroll = false;
          click-method = "clickfinger";
          accel-profile = "adaptive";
        };

        mouse = {
          accel-profile = "flat";
          accel-speed = 1.0;
        };

        focus-follows-mouse = {
          enable = true;
          max-scroll-amount = "0%";
        };
        warp-mouse-to-focus.enable = false;
      };

      # ── Cursor ────────────────────────────────────────────────
      cursor = {
        theme = config.stylix.cursor.name;
        inherit (config.stylix.cursor) size;
      };

      # ── Environment ───────────────────────────────────────────
      environment = {
        IN_NIX_SHELL = null; # Prevent nix-shell env from leaking into the session
        NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        QT_QPA_PLATFORM = "wayland";
        QT_AUTO_SCREEN_SCALE_FACTOR = "1";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        XDG_SESSION_TYPE = "wayland";
        XDG_CURRENT_DESKTOP = "niri";
        SDL_VIDEODRIVER = "wayland";
        CLUTTER_BACKEND = "wayland";
        ANKI_WAYLAND = "1";
        XCURSOR_SIZE =
          if isThinkpad
          then "20"
          else "24";
      };

      # ── Layout ────────────────────────────────────────────────
      layout = {
        gaps = gaps-in;
        center-focused-column = "on-overflow";
        always-center-single-column = true;

        border = {
          enable = true;
          width = border-size;
          active.gradient = {
            from = accent;
            to = accentAlt;
            angle = 45;
          };
          inactive.color = inactive;
        };

        focus-ring.enable = false;

        shadow = {
          enable = true;
          softness = 30;
          spread = 5;
          offset = {
            x = 0;
            y = 5;
          };
          color = "#00000070";
        };

        tab-indicator = {
          hide-when-single-tab = true;
          place-within-column = true;
          position = "left";
          gap = 4;
          width = 4;
          corner-radius = rounding * 1.0;
          active.color = accent;
          inactive.color = inactive;
        };

        preset-column-widths = [
          {proportion = 1.0 / 3.0;}
          {proportion = 1.0 / 2.0;}
          {proportion = 2.0 / 3.0;}
        ];

        preset-window-heights = [
          {proportion = 1.0 / 3.0;}
          {proportion = 1.0 / 2.0;}
          {proportion = 2.0 / 3.0;}
        ];

        default-column-width = {proportion = 1.0 / 2.0;};
      };

      # ── Autostart ─────────────────────────────────────────────
      # Noctalia handles: bar, notifications, clipboard, OSD,
      # wallpaper, lock screen, app launcher.
      spawn-at-startup = [
        {command = ["noctalia-shell"];}
        {command = ["xwayland-satellite"];}
        {command = ["wl-paste" "--type" "text" "--watch" "cliphist" "store"];}
        {command = ["wl-paste" "--type" "image" "--watch" "cliphist" "store"];}
      ];

      # ── Switch events ─────────────────────────────────────────
      switch-events = {
        lid-close.action.spawn = ["noctalia-shell" "ipc" "call" "lockScreen" "lock"];
      };

      # ── Noctalia layer rules ─────────────────────────────────
      # Blurred overview wallpaper (Noctalia docs Option 1)
      layer-rules = [
        {
          matches = [{namespace = "^noctalia-overview.*";}];
          place-within-backdrop = true;
        }
      ];

      # ── Debug ────────────────────────────────────────────────
      # Allow Noctalia notification actions and window activation
      debug.honor-xdg-activation-with-invalid-serial = {};

      # ── Window rules ──────────────────────────────────────────
      window-rules = [
        # Global: rounded corners + active opacity
        {
          geometry-corner-radius = let
            r = rounding * 1.0;
          in {
            top-left = r;
            top-right = r;
            bottom-left = r;
            bottom-right = r;
          };
          clip-to-geometry = true;
          draw-border-with-background = false;
          opacity = active-opacity;
        }

        # Inactive opacity
        {
          matches = [{is-focused = false;}];
          opacity = inactive-opacity;
        }

        # Floating: PiP windows
        {
          matches = [
            {
              app-id = "^firefox$";
              title = "^Picture-in-Picture$";
            }
            {
              app-id = "^zen$";
              title = "^Picture-in-Picture$";
            }
          ];
          open-floating = true;
        }

        # Floating: dialogs and utilities
        {
          matches = [
            {app-id = "^pavucontrol$";}
            {app-id = "^blueman-manager$";}
            {app-id = "^nm-connection-editor$";}
            {app-id = "^gnome-calculator$";}
            {title = "^Open File$";}
            {title = "^Save File$";}
          ];
          open-floating = true;
        }

        # Floating: Telegram mini apps
        {
          matches = [
            {
              app-id = "^org\\.telegram\\.desktop$";
              title = "^Mini App:.*$";
            }
          ];
          open-floating = true;
        }

        # Block password managers from screencasts
        {
          matches = [
            {app-id = "^org\\.keepassxc\\.KeePassXC$";}
            {app-id = "^Bitwarden$";}
          ];
          block-out-from = "screencast";
        }

        # Terminal transparency
        {
          matches = [
            {app-id = "^Alacritty$";}
            {app-id = "^kitty$";}
            {app-id = "^foot$";}
            {app-id = "^com\\.mitchellh\\.ghostty$";}
          ];
          opacity = 0.95;
          draw-border-with-background = false;
        }

        # Browser transparency
        {
          matches = [{app-id = "^zen$";}];
          opacity = 0.95;
        }
      ];
    };
  };
}
