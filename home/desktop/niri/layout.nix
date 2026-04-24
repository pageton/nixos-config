{ config, ... }:
let
  inherit (config.theme) border-size gaps-in rounding;
  inherit (config.lib.stylix) colors;
  accent = "#${colors.base0D}";
  accentAlt = "#${colors.base0E}";
  inactive = "#${colors.base03}";
in
{
  programs.niri.settings.layout = {
    gaps = gaps-in;
    center-focused-column = "on-overflow";
    always-center-single-column = true;
    background-color = "transparent";

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
      { proportion = 1.0 / 3.0; }
      { proportion = 1.0 / 2.0; }
      { proportion = 2.0 / 3.0; }
    ];

    preset-window-heights = [
      { proportion = 1.0 / 3.0; }
      { proportion = 1.0 / 2.0; }
      { proportion = 2.0 / 3.0; }
    ];

    default-column-width.proportion = 1.0 / 2.0;
  };
}
