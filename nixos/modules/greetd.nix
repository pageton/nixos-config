# Noctalia Greeter — greetd-based display manager matching the Noctalia v5
# shell aesthetic. Replaces DankGreeter (DMS-themed) and SDDM.
#
# The greeter syncs palette/wallpaper/font from the running Noctalia shell via
# "Settings -> Security -> Noctalia Greeter -> Sync Now", which writes
# /var/lib/noctalia-greeter/sync.toml. Declarative greeter.toml (settings below)
# wins over synced keys; both layer under the live shell appearance.
#
# IMPORTANT: this is a system-level, boot-critical service. If the greeter fails,
# you can still log in via TTY (Ctrl+Alt+F2) and `nh os switch` to revert.
{
  lib,
  user,
  constants,
  pkgs,
  ...
}:
{
  # Disable SDDM — only one display manager may be active (asserted in
  # nixos/modules/validation.nix: SDDM && greetd is rejected).
  services.displayManager.sddm.enable = lib.mkForce false;

  # Noctalia Greeter. The module auto-enables services.greetd and sets the
  # default_session command to noctalia-greeter-session. niri is the greeter's
  # compositor (matches the session compositor). Appearance flows from the
  # shell sync; cursor is pinned here for parity with constants.theme.
  programs.noctalia-greeter = {
    enable = true;
    settings = {
      cursor = {
        theme = constants.theme.cursor;
        size = constants.theme.cursorSize;
        path = "${pkgs.bibata-cursors}/share/icons";
      };
      session.default = "niri";
    };
  };

  # Default session after login = niri.
  services.displayManager.defaultSession = lib.mkDefault "niri";
}
