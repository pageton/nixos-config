# Fuzzel is a launcher for Wayland, inspired by rofi/dmenu.
# This configuration mirrors the wofi theme style with optimizations.
{
  config,
  pkgs,
  lib,
  ...
}: let
  accent = "#${config.lib.stylix.colors.base0D}";
  background = "${config.lib.stylix.colors.base00}ff";
  background-alt = "${config.lib.stylix.colors.base01}ff";
  foreground = "${config.lib.stylix.colors.base05}ff";
  rounding = toString config.theme.rounding;
in {
  programs.fuzzel = {
    enable = true;

    settings = lib.mkForce {
      main = {
        # Font configuration - matches wofi style
        # font = "${font}:size=${font-size}:weight=500";
        # use-bold = "yes";
        dpi-aware = "auto";

        # Prompt and display
        prompt = "\"Apps \""; # Trailing space preserved with quotes
        placeholder = "Search applications...";

        # Icons - use Tela for modern, comprehensive app icon coverage
        icons-enabled = "yes";
        image-size-ratio = "0.5";

        # Matching behavior - optimized for performance
        fields = "name,generic,comment,categories,filename,keywords";
        match-mode = "fzf"; # fzf-style matching for better results
        sort-result = "yes";
        match-counter = "no"; # Disabled for cleaner look
        filter-desktop = "no"; # Show all apps regardless of DE

        # Display settings - matches wofi dimensions
        lines = "8";
        width = "45"; # Similar to wofi's 450px
        line-height = "24";

        # Padding and spacing - matches wofi's 20px outer-box, 6px entry padding
        horizontal-pad = "20";
        vertical-pad = "20";
        inner-pad = "14"; # Space between input and list (wofi: 20px scroll margin + adjustments)

        # Window behavior
        layer = "overlay";
        anchor = "center";
        exit-on-keyboard-focus-loss = "yes";

        # Terminal for launching terminal apps
        terminal = "${pkgs.foot}/bin/foot";

        # Performance optimizations
        render-workers = "0"; # Auto-detect based on CPU cores
        match-workers = "0"; # Auto-detect based on CPU cores
        delayed-filter-ms = "300"; # Delay filtering for large datasets
        delayed-filter-limit = "20000"; # Only delay when >20k matches

        # Other settings
        tabs = "8";
        hide-before-typing = "no";
        password-character = "*";
      };

      colors = {
        # Background colors
        inherit background;

        # Text colors - prompt uses different color for distinction
        text = foreground;
        prompt = "${config.lib.stylix.colors.base0A}ff";  # Yellow for "Apps" label
        input = foreground;  # Input text color
        placeholder = "${config.lib.stylix.colors.base04}ff";

        # Match highlighting
        match = accent;

        # Selection colors - uses accent for selected items like wofi
        selection = "${accent}ff";
        selection-text = foreground;
        selection-match = foreground;

        # Counter color (not displayed, but defined)
        counter = background-alt;

        # Border color
        border = accent;
      };

      border = {
        width = "0"; # No border like wofi
        radius = rounding;
      };

      dmenu = {
        exit-immediately-if-empty = "no";
      };
    };
  };
}
