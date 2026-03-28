# X11 is intentionally disabled (Wayland-only niri stack).
{
  services.xserver = {
    enable = false;

    xkb = {
      layout = "us";
      variant = "";
    };
  };
}
