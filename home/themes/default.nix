# Catppuccin Mocha theme — system-wide theming via Stylix.
# Palette: https://github.com/catppuccin/catppuccin
{
  lib,
  pkgs,
  config,
  inputs,
  system,
  ...
}:
let
  # Catppuccin Mocha base16 palette — single source of truth.
  # Referenced by both Stylix and the wallpaper generator.
  palette = {
    base00 = "1E1E2E"; # Default Background (Base)
    base01 = "181825"; # Lighter Background (Mantle)
    base02 = "313244"; # Selection Background (Surface0)
    base03 = "45475A"; # Comments, Invisibles (Surface1)
    base04 = "585B70"; # Dark Foreground (Surface2)
    base05 = "CDD6F4"; # Default Foreground (Text)
    base06 = "F5E0DC"; # Light Foreground (Flamingo)
    base07 = "BAC2DE"; # Light Background (Subtext0)
    base08 = "F38BA8"; # Variables, XML Tags (Red)
    base09 = "FAB387"; # Integers, Boolean, Constants (Peach)
    base0A = "F9E2AF"; # Classes, Search Text (Yellow)
    base0B = "A6E3A1"; # Strings, Diff Inserted (Green)
    base0C = "94E2D5"; # Support, RegExp (Teal)
    base0D = "89B4FA"; # Functions, Methods, Accent (Blue)
    base0E = "CBA6F7"; # Keywords, Diff Changed (Mauve)
    base0F = "F2CDCD"; # Deprecated (Pink)
  };
in
{
  # === Theme Options (typed submodule) ===
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

  config = {
    # === Font Packages ===
    # Consolidated here so fonts live alongside the theme that selects them.
    home.packages = with pkgs; [
      dejavu_fonts # Fallback sans-serif font
      jetbrains-mono # Primary monospace font
      noto-fonts # Comprehensive font collection
      noto-fonts-lgc-plus # Extended language coverage
      texlivePackages.hebrew-fonts # Hebrew language support
      noto-fonts-color-emoji # Emoji font support
      font-awesome # Icon font for UI elements
      powerline-fonts # Special characters for status bars
      powerline-symbols # Additional powerline symbols
      nerd-fonts.jetbrains-mono # JetBrains Mono with Nerd Font patches
      meslo-lgs-nf
      fira-code
    ];

    # === Stylix Configuration ===
    stylix = {
      enable = true;
      enableReleaseChecks = false;

      targets = {
        gtk.enable = true;
        qt.enable = true;
        neovim.enable = false;
        nvf.enable = false;
        alacritty.enable = true;
        waybar.enable = false;
        nixcord.enable = false;
        zen-browser = {
          enable = true;
          profileNames = [ "default" ];
        };
      };

      # Catppuccin Mocha
      # See https://tinted-theming.github.io/tinted-gallery/ for more schemes
      base16Scheme = palette;

      icons = {
        enable = true;
        package = pkgs.gruvbox-plus-icons;
        dark = "Gruvbox-Plus-Dark";
        light = "Gruvbox-Plus-Light";
      };

      cursor = {
        name = "Bibata-Modern-Ice";
        size = 24;
        package = pkgs.bibata-cursors;
      };

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrains Mono Nerd Font";
        };
        sansSerif = {
          package = pkgs.source-sans;
          name = "Source Sans 3";
        };
        serif = config.stylix.fonts.sansSerif;
        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };
        sizes = {
          applications = 13;
          desktop = 13;
          popups = 13;
          terminal = 13;
        };
      };

      polarity = "dark";

      # Wallpaper — references palette for DRY color usage.
      # Uses all 6 logo slots with distinct Catppuccin Mocha accent colors.
      image = "${
        inputs.nix-wallpaper.packages.${system}.default.override {
          backgroundColor = "#${palette.base00}";
          logoColors = {
            color0 = "#${palette.base0D}"; # Blue
            color1 = "#${palette.base0E}"; # Mauve
            color2 = "#${palette.base0C}"; # Teal
            color3 = "#${palette.base09}"; # Peach
            color4 = "#${palette.base0B}"; # Green
            color5 = "#${palette.base0F}"; # Pink
          };
        }
      }/share/wallpapers/nixos-wallpaper.png";
    };
  };
}
