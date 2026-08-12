# Qt theming and configuration.
# Uses pkgs (unstable) — qt5ct/qt6ct are small config tools; no benefit from stable.

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
