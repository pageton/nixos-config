# X server configuration.

{
  services.xserver = {
    enable = true;

    xkb = {
      layout = "us";
      variant = "";
    };
  };
}
