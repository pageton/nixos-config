# Qt theming and configuration

{ pkgs, ... }:

{
  qt = {
    enable = true;
    platformTheme.name = "qtct";
  };

  home.packages = with pkgs; [
    libsForQt5.qt5ct
    qt6Packages.qt6ct
  ];
}
