{ constants, ... }: {
  programs.niri.settings.input = {
    keyboard = {
      xkb = { inherit (constants.keyboard) layout options; };
      repeat-delay = 300;
      repeat-rate = 30;
    };

    touchpad = {
      tap = true;
      dwt = true;
      dwtp = true;
      natural-scroll = false;
      click-method = "clickfinger";
      accel-profile = "adaptive";
    };

    mouse = {
      accel-profile = "flat"; # no mouse acceleration — raw 1:1 input
      accel-speed = 1.0; # doubled speed (flat profile: 0.0 = 1:1, 1.0 = 2x)
    };

    # Focus follows mouse without auto-scrolling; warp off — cursor stays out of the way.
    focus-follows-mouse = {
      enable = true;
      max-scroll-amount = "0%";
    };
    warp-mouse-to-focus.enable = false;
    workspace-auto-back-and-forth = true;
  };
}
