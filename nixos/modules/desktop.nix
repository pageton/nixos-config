# Desktop session: Niri compositor, Noctalia Greeter, XDG portals, keyboard.
{
  lib,
  pkgs,
  inputs,
  constants,
  ...
}:
{
  # === Niri scrollable tiling Wayland compositor ===
  imports = [ inputs.niri.nixosModules.niri ];

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  # XWayland compatibility via xwayland-satellite
  environment.systemPackages = with pkgs; [
    xwayland-satellite

    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-gnome
    xdg-utils
    thunar # File manager
    tumbler # Thumbnail service for Thunar
  ];

  # Security services for compositor
  security.polkit.enable = true;

  # niri-flake's user service runs outside the compositor session on this host,
  # causing polkit-gnome to loop with "No session for pid". Start the agent
  # from Niri startup (home/niri) instead.
  systemd.user.services.niri-flake-polkit.enable = lib.mkForce false;

  # === Noctalia Greeter ===
  # greetd-based display manager matching the Noctalia v5 shell aesthetic.
  # Replaces DankGreeter (DMS-themed) and SDDM.
  #
  # The greeter syncs palette/wallpaper/font from the running Noctalia shell via
  # "Settings -> Security -> Noctalia Greeter -> Sync Now", which writes
  # /var/lib/noctalia-greeter/sync.toml. Declarative greeter.toml (settings below)
  # wins over synced keys; both layer under the live shell appearance.
  #
  # IMPORTANT: this is a system-level, boot-critical service. If the greeter fails,
  # you can still log in via TTY (Ctrl+Alt+F2) and `nh os switch` to revert.
  services.displayManager = {
    # Disable SDDM — only one display manager may be active (asserted in
    # validation.nix: SDDM && greetd is rejected).
    sddm.enable = lib.mkForce false;

    # The module auto-enables services.greetd and sets the default_session
    # command to noctalia-greeter-session. niri is the greeter's compositor
    # (matches the session compositor). Appearance flows from the shell sync;
    # cursor is pinned here for parity with constants.theme.
    noctalia-greeter = {
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
    defaultSession = lib.mkDefault "niri";
  };

  # === Keyboard layout (xkb, used by console + greeter + XWayland) ===
  services.xserver = {
    enable = true;
    xkb = {
      inherit (constants.keyboard) layout variant options;
    };
  };

  # === XDG Desktop Portal ===
  # FileChooser via GTK; ScreenCast/Screenshot via GNOME portal
  # (niri implements the GNOME ScreenCast portal protocol).
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-gnome
    ];
    config = {
      common = {
        # Prefer GNOME portal as primary backend for niri Wayland sessions.
        # Keep GTK only for FileChooser to avoid early-session GTK backend churn.
        default = [ "gnome" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      };
    };
  };

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
    XDG_SESSION_TYPE = "wayland";
    GTK_USE_PORTAL = "1";
    NO_AT_BRIDGE = "1";
  };

  systemd.user.services.xdg-desktop-portal-gtk.serviceConfig = {
    Restart = "on-failure";
    RestartSec = "1s";
  };
}
