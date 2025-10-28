{
  homeStateVersion,
  user,
  pkgs,
  pkgsStable,
  ...
}:

{
  imports = [
    ./system
    ./programs
    ./scripts
    ./secrets
    ../themes/catppuccin.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;
  };

  nixpkgs.config.allowUnfree = true;

  home.packages =
    let
      # Import packages from custom package definitions
      Pkgs = import ./packages { inherit pkgs pkgsStable; };
    in
    # All packages from custom definitions
    Pkgs;

  home.file.".face.icon" = {
    source = ./profile_picture.png;
  };

  home.sessionVariables = {
    # Qt platform preference - Wayland first, X11 fallback
    QT_QPA_PLATFORM = "xcb";

    # Maintain Qt5 compatibility for legacy applications
    DISABLE_QT5_COMPAT = "0";

    # Force dark theme in Calibre e-book manager
    CALIBRE_USE_DARK_PALETTE = "1";

    # QT/Wayland fixes for Telegram and other Qt applications
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1"; # Let Hyprland handle decorations
    QT_AUTO_SCREEN_SCALE_FACTOR = "1"; # Enable automatic scaling
    QT_ENABLE_HIGHDPI_SCALING = "1"; # Enable high DPI scaling
    GDK_SCALE = "1"; # GTK scaling for consistency
    GDK_DPI_SCALE = "1"; # GTK DPI scaling
  };

  stylix.targets = {
    # Enable core desktop theming
    gtk.enable = true; # Apply theme to GTK applications
    qt.enable = true; # Apply theme to Qt applications
    # Configure Zen Browser theming
    zen-browser = {
      enable = true; # Enable Zen Browser theming
      profileNames = [ "default" ]; # Apply to default profile
    };
  };

  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;
}
