{ pkgs, ... }:
{
  home.packages = with pkgs; [
    networkmanagerapplet
    tesseract
    zbar
    translate-shell
    wl-screenrec
    gifski
  ];
}
