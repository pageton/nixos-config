# Stylix configuration — system-wide theming, fonts, cursor, icons, and wallpaper.
{
  pkgs,
  config,
  constants,
  ...
}:
let
  palette = import ./palette.nix;
in
{
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
      nixcord.enable = false;
      # Noctalia v5 has NO stylix target (unlike v4's noctalia-shell.enable).
      # Theme + wallpaper are hand-mirrored via programs.noctalia.settings in
      # home/noctalia/settings.nix (Catppuccin builtin palette + the
      # same repo-tracked image referenced below).
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

    # Wallpaper — repo-tracked image (current user pick, promoted to default).
    # Replaces the generated nix-wallpaper derivation.
    image = ../../assets/wallhaven_x6x3gz.png;
  };
}
