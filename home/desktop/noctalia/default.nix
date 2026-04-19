# Noctalia — sleek, minimal Quickshell-based desktop shell for niri.
# Replaces waybar, swaync, fuzzel, swaylock, and power menu.
{
  config,
  hostname,
  pkgs,
  lib,
  ...
}: let
  isThinkpad = hostname == "thinkpad";
in {
  services.status-notifier-watcher.enable = true;

  programs.noctalia-shell = {
    enable = true;

    # ── Colors (override Stylix) ──────
    colors = {
      mPrimary = lib.mkForce "#${config.lib.stylix.colors.base0D}"; # CrystalBlue - for app icon focus dots
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
            {
              id = "Clock";
              formatHorizontal = "hh:mm A ddd, MMM dd";
            }
            {
              id = "SystemMonitor";
              compactMode = false;
              showGpuTemp = true;
              showNetworkStats = true;
              showDiskUsage = true;
            }
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
              focusedColor = "tertiary"; # Active workspace indicator color
              occupiedColor = "secondary"; # Non-active workspace with windows
              emptyColor = "secondary"; # Empty workspace
            }
          ];
          right =
            [
              {id = "Tray";}
              {id = "Network";}
              {id = "NotificationHistory";}
              {id = "plugin:tailscale";} # Tailscale status
              {id = "Battery";}
              {id = "Volume";}
              {id = "Microphone";}
            ]
            ++ lib.optionals isThinkpad [{id = "Brightness";}]
            ++ [
              {
                id = "ControlCenter";
                useDistroLogo = false;
                icon = "settings";
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
        predefinedScheme = "Catppuccin";
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

    plugins = {
      version = 2;
      sources = [
        {
          enabled = true;
          name = "Noctalia Plugins";
          url = "https://github.com/noctalia-dev/noctalia-plugins";
        }
      ];
      states = {
        tailscale = {
          enabled = true;
          sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
        };
      };
    };

    pluginSettings = {
      tailscale = {
        refreshInterval = 5000;
        compactMode = true;
        showIpAddress = false;
        showPeerCount = false;
        terminalCommand = "alacritty";
      };
    };
  };

  # nm-connection-editor for advanced network config
  # (nm-applet service is enabled in home.nix; this provides the GUI editor)
  home.packages = [pkgs.networkmanagerapplet];
}
