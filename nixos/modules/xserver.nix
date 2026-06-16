# X server for XWayland compatibility on Niri.
{ constants, ... }: {
  services.xserver = {
    enable = true;
    xkb = { inherit (constants.keyboard) layout variant options; };
  };
}
