# Stylix configuration — system-wide theming, fonts, cursor, icons, and wallpaper.
{
  pkgs,
  config,
  constants,
  inputs,
  system,
  ...
}: let
  palette = import ./palette.nix;
in {
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
    autoEnable = false;
    enableReleaseChecks = false;

    targets = {
      gtk.enable = true;
      qt.enable = true;
      neovim.enable = false;
      nvf.enable = false;
      alacritty.enable = true;
      ghostty.enable = true;
      zellij.enable = true;
      waybar.enable = false;
      nixcord.enable = false;
      # Noctalia v5 has NO stylix target (unlike v4's noctalia-shell.enable).
      # Theme + wallpaper are hand-mirrored via programs.noctalia.settings in
      # home/desktop/noctalia/settings.nix (Catppuccin builtin palette + the
      # same nix-wallpaper derivation referenced below).
      librewolf = {
        enable = true;
        profileNames = [
          "personal"
          "work"
          "banking"
          "shopping"
          "illegal"
          "i2pd"
        ];
      };
    };

    # Catppuccin Mocha
    # See https://tinted-theming.github.io/tinted-gallery/ for more schemes
    base16Scheme = palette;

    icons = {
      enable = true;
      package = pkgs.gruvbox-plus-icons;
      dark = constants.theme.iconDark;
      light = constants.theme.iconLight;
    };

    cursor = {
      name = constants.theme.cursor;
      size = constants.theme.cursorSize;
      package = pkgs.bibata-cursors;
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = constants.font.monoNerd;
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
        applications = constants.font.sizeApplications;
        desktop = constants.font.size;
        popups = constants.font.size;
        terminal = constants.font.size;
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
}
