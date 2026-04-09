# Kanagawa Wave theme — system-wide theming via Stylix.
# Palette: https://github.com/rebelot/kanagawa.nvim
{
  lib,
  pkgs,
  config,
  inputs,
  system,
  ...
}:
let
  # Kanagawa Wave base16 palette — single source of truth.
  # Referenced by both Stylix and the wallpaper generator.
  palette = {
    base00 = "1F1F28"; # Default Background (sumiInk1)
    base01 = "16161D"; # Lighter Background (sumiInk0)
    base02 = "223249"; # Selection Background (winterBlue)
    base03 = "54546D"; # Comments, Invisibles (sumiInk6)
    base04 = "727169"; # Dark Foreground (oldWhite)
    base05 = "DCD7BA"; # Default Foreground (fujiWhite)
    base06 = "C8C093"; # Light Foreground (oldWhite lighter)
    base07 = "717C7C"; # Light Background
    base08 = "C34043"; # Variables, XML Tags (autumnRed)
    base09 = "FFA066"; # Integers, Boolean, Constants (surimiOrange)
    base0A = "C0A36E"; # Classes, Search Text (boatYellow2)
    base0B = "76946A"; # Strings, Diff Inserted (autumnGreen)
    base0C = "6A9589"; # Support, RegExp (waveAqua1)
    base0D = "7E9CD8"; # Functions, Methods, Accent (crystalBlue)
    base0E = "957FB8"; # Keywords, Diff Changed (oniViolet)
    base0F = "D27E99"; # Deprecated (sakuraPink)
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
        helix.enable = false;
        neovim.enable = false;
        nvf.enable = false;
        alacritty.enable = false;
        waybar.enable = false;
        nixcord.enable = false;
        zen-browser = {
          enable = true;
          profileNames = [ "default" ];
        };
      };

      # Kanagawa Wave
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
      # Uses all 6 logo slots with distinct Kanagawa accent colors.
      image = "${
        inputs.nix-wallpaper.packages.${system}.default.override {
          backgroundColor = "#${palette.base00}";
          logoColors = {
            color0 = "#${palette.base0D}"; # crystalBlue
            color1 = "#${palette.base0E}"; # oniViolet
            color2 = "#${palette.base0C}"; # waveAqua1
            color3 = "#${palette.base09}"; # surimiOrange
            color4 = "#${palette.base0B}"; # autumnGreen
            color5 = "#${palette.base0F}"; # sakuraPink
          };
        }
      }/share/wallpapers/nixos-wallpaper.png";
    };
  };
}
