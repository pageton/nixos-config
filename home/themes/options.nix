# Theme submodule options — visual preferences for the desktop environment.
{ lib, config, ... }:
{
  options.theme = lib.mkOption {
    type = lib.types.submodule {
      options = {
        rounding = lib.mkOption {
          type = lib.types.int;
          default = 15;
          description = "Corner rounding radius in pixels.";
        };
        gaps-in = lib.mkOption {
          type = lib.types.int;
          default = 8;
          description = "Inner gaps between windows in pixels.";
        };
        gaps-out = lib.mkOption {
          type = lib.types.int;
          default = 16;
          description = "Outer gaps between windows and screen edges.";
        };
        active-opacity = lib.mkOption {
          type = lib.types.float;
          default = 1.0;
          description = "Opacity of focused windows (0.0–1.0).";
        };
        inactive-opacity = lib.mkOption {
          type = lib.types.float;
          default = 1.0;
          description = "Opacity of unfocused windows (0.0–1.0).";
        };
        blur = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable window blur effects.";
        };
        border-size = lib.mkOption {
          type = lib.types.int;
          default = 3;
          description = "Window border width in pixels.";
        };
        animation-speed = lib.mkOption {
          type = lib.types.enum [
            "fast"
            "medium"
            "slow"
          ];
          default = "medium";
          description = "Animation speed preset.";
        };
        fetch = lib.mkOption {
          type = lib.types.enum [
            "nerdfetch"
            "neofetch"
            "pfetch"
            "none"
          ];
          default = "none";
          description = "System fetch tool to display in terminal.";
        };
        textColorOnWallpaper = lib.mkOption {
          type = lib.types.str;
          default = config.lib.stylix.colors.base05;
          description = "Text color for wallpaper overlays (lockscreen, display manager).";
        };
        bar = lib.mkOption {
          type = lib.types.submodule {
            options = {
              position = lib.mkOption {
                type = lib.types.enum [
                  "top"
                  "bottom"
                ];
                default = "top";
                description = "Bar position on screen.";
              };
              transparent = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable bar transparency.";
              };
              transparentButtons = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable transparent bar buttons.";
              };
              floating = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Enable floating bar mode.";
              };
            };
          };
          default = { };
          description = "Bar (Hyprpanel) configuration.";
        };
      };
    };
    default = { };
    description = "Theme configuration options.";
  };
}
