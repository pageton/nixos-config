{ constants, ... }:
{
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

    # Focus follows mouse, but view does not auto-scroll to other workspaces.
    # This means mouse focus changes silently without shifting the visible area.
    focus-follows-mouse = {
      enable = true;
      max-scroll-amount = "0%"; # never auto-scroll when focus crosses workspaces
    };
    # NOTE: warp-mouse-to-focus is off, so keyboard focus changes won't move the cursor.
    # Combined with focus-follows-mouse, the next mouse movement may snap focus back.
    # This is intentional — the cursor stays out of the way until you use the mouse.
    warp-mouse-to-focus.enable = false;
    workspace-auto-back-and-forth = true;
  };
}
