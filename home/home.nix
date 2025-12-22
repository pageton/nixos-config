{
  homeStateVersion,
  user,
  pkgs,
  pkgsStable,
  lib,
  hostname,
  ...
}: {
  imports =
    [
      ./secrets
      ./programs
      ./scripts
    ]
    ++ lib.optional (hostname != "server") ./system
    ++ lib.optional (hostname != "server") ./themes/catppucin.nix;

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;
  };

  nixpkgs.config.allowUnfree = true;

  home.packages = lib.concatLists [
    (
      if hostname != "server"
      then let Pkgs = import ./packages {inherit pkgs pkgsStable;}; in Pkgs
      else []
    )

    (
      if hostname == "server"
      then [
        pkgs.just
        pkgs.vim
      ]
      else []
    )
  ];

  home.file.".face.icon" = lib.mkIf (hostname != "server") {
    source = ./profile_picture.png;
  };

  home.sessionVariables = lib.mkIf (hostname != "server") {
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

  fonts.fontconfig.enable = lib.mkDefault (hostname != "server");
  programs.home-manager.enable = true;
}
