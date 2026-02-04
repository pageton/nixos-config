# Noctalia — sleek, minimal Quickshell-based desktop shell for niri.
# Replaces waybar, swaync, fuzzel, swaylock, and power menu.
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Fetch Noctalia plugins repository
  noctalia-plugins = pkgs.fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "noctalia-plugins";
    rev = "main";
    sha256 = "sha256-pjlfjfZAViv+7d9VVTvdXZGRkUGmb0HKjAXm7VnJLiE=";
  };
in {
  programs.noctalia-shell = {
    enable = true;

    # ── Colors (override Stylix) ──────
    colors = {
      mPrimary = lib.mkForce "#${config.lib.stylix.colors.base0D}";  # CrystalBlue - for app icon focus dots
    };

    # ── Settings (written to ~/.config/noctalia/settings.json) ──────
    settings = {
      # Skip the first-run wizard and migrations (read-only Nix store symlink)
      setupCompleted = true;
      settingsVersion = 46;

      bar = {
        position = "top";
        floating = true;
        density = "comfortable";
        backgroundOpacity = lib.mkForce 0.95;

        # ── Widget layout ──────────────────────────────────────────
        widgets = {
          left = [
            {id = "Launcher";}
            {id = "Clock";}
            {id = "SystemMonitor";}
            {id = "ActiveWindow";}
            {id = "MediaMini";}
          ];
          center = [
            {
              id = "Workspace";
              showApplications = true;
              labelMode = "index";
              hideUnoccupied = false;
              showLabelsOnlyWhenOccupied = true;
              colorizeIcons = false;
              iconScale = 0.8;
              showBadge = true;
              enableScrollWheel = true;
              focusedColor = "tertiary";     # Active workspace indicator color
              occupiedColor = "secondary";   # Non-active workspace with windows
              emptyColor = "secondary";      # Empty workspace
            }
          ];
          right = [
            {id = "Tray";}
            {id = "NotificationHistory";}
            {id = "plugin:clipper";} # Clipboard manager
            {id = "plugin:keybind-cheatsheet";} # Keybind cheatsheet
            {id = "Battery";}
            {id = "Volume";}
            {id = "Brightness";}
            {
              id = "ControlCenter";
              useDistroLogo = true;
              colorizeDistroLogo = true;
              colorizeSystemIcon = "primary";
            }
          ];
        };
      };

      general = {
        radiusRatio = 1.2; # Slightly rounder to match rounding=15
        animationSpeed = 1.0;
        dimDesktop = true;
        lockOnSuspend = true;
      };

      wallpaper = {
        enabled = true;
        defaultWallpaper = toString config.stylix.image;
        fillMode = "crop";
      };

      colorSchemes = {
        darkMode = true;
        predefinedScheme = "Kanagawa";
        useWallpaperColors = false;
      };

      ui = {
        fontDefault = config.stylix.fonts.sansSerif.name;
        fontFixed = config.stylix.fonts.monospace.name;
        tooltipsEnabled = true;
      };

      dock = {
        enabled = false;
      };

      appLauncher = {
        position = "center";
        sortByMostUsed = true;
        enableClipboardHistory = true;
      };

      notifications = {
        location = "top_right";
        overlayLayer = true;
      };

      osd = {
        enabled = true;
        location = "top_right";
      };

      location = {
        name = "Basra, Iraq"; # Weather location
        weatherEnabled = true;
        use12hourFormat = true;
      };
    };
  };

  # nm-connection-editor for advanced network config (Noctalia handles the applet)
  # Plugin dependencies (cliphist and wl-clipboard already in hyprland.nix)
  home.packages = [pkgs.networkmanagerapplet];

  # ── Noctalia Plugins ──────────────────────────────────────────
  xdg.configFile = {
    "noctalia/plugins/currency-exchange".source = "${noctalia-plugins}/currency-exchange";
    "noctalia/plugins/keybind-cheatsheet".source = "${noctalia-plugins}/keybind-cheatsheet";
    "noctalia/plugins/clipper".source = "${noctalia-plugins}/clipper";
  };
}
