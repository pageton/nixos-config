# Noctalia — sleek, minimal Quickshell-based desktop shell for niri.
# Replaces waybar, swaync, fuzzel, swaylock, and power menu.
{ config, lib, ... }:
let
  animationSpeedMap = {
    fast = 1.5;
    medium = 1.0;
    slow = 0.6;
  };
in
{
  imports = [
    ./bar.nix
    ./plugins.nix
    ./packages.nix
  ];

  services.status-notifier-watcher.enable = true;

  programs.noctalia-shell = {
    enable = true;

    colors = {
      mPrimary = lib.mkForce "#${config.lib.stylix.colors.base0D}";
    };

    settings = {
      setupCompleted = true;
      settingsVersion = 46;

      general = {
        radiusRatio = config.theme.rounding / 12.5;
        animationSpeed = animationSpeedMap.${config.theme.animation-speed};
        dimDesktop = config.theme.blur;
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

      controlCenter = {
        shortcuts = {
          left = [
            { id = "Network"; }
            { id = "Bluetooth"; }
            { id = "NoctaliaPerformance"; }
          ];
          right = [
            { id = "Notifications"; }
            { id = "KeepAwake"; }
            { id = "NightLight"; }
          ];
        };
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
        name = "Basra, Iraq";
        weatherEnabled = false;
        use12hourFormat = true;
      };
    };
  };
}
