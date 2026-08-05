# DankGreeter — greetd-based display manager using the DMS lock-screen aesthetic.
# Replaces SDDM. The greeter runs niri as its compositor and mirrors the user's
# DMS settings (wallpaper, theme, colors) so the login screen matches the desktop.
#
# IMPORTANT: this is a system-level, boot-critical service. If the greeter fails,
# you can still log in via TTY (Ctrl+Alt+F2) and `nh os switch` to revert.
{ lib, user, ... }:
let
  profileImage = ../../home/assets/profile_picture.png;
in
{
  # Disable SDDM — only one display manager may be active (asserted in
  # nixos/modules/validation.nix: SDDM && greetd is rejected).
  services.displayManager.sddm.enable = lib.mkForce false;

  # DankGreeter. The greeter module auto-enables services.greetd and sets the
  # default_session command to the dms-greeter script. niri is the greeter's
  # compositor (matches the session compositor). configHome mirrors this user's
  # DMS config (settings.json, session.json with wallpaper, dms-colors.json)
  # into the greeter's cache dir so login looks like the desktop.
  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${user}";
  };

  # configHome syncs DMS settings, session state, and colors, but not the user
  # avatar. Install it in the per-user greeter cache where DankGreeter looks
  # before AccountsService and ~/.face.
  systemd.tmpfiles.settings."20-dms-greeter-profile" = {
    "/var/lib/dms-greeter/users/${user}".d = {
      user = "greeter";
      group = "greeter";
      mode = "0750";
    };
    "/var/lib/dms-greeter/users/${user}/profile.png"."L+".argument = toString profileImage;
  };

  # Default session after login = niri.
  services.displayManager.defaultSession = lib.mkDefault "niri";
}
