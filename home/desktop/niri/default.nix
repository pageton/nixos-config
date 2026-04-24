# Niri scrollable-tiling Wayland compositor — Home Manager configuration.
{
  config,
  constants,
  hostname,
  pkgs,
  ...
}:
let
  isThinkpad = hostname == "thinkpad";
in
{
  imports = [
    ./animations.nix
    ./bindings.nix
    ./idle.nix
    ./input.nix
    ./layout.nix
    ./lock.nix
    ./rules.nix
    ./_auth-float.nix
  ];

  services.playerctld.enable = true;

  home.packages = [ pkgs.xwayland-satellite ];

  programs.niri.settings = {
    prefer-no-csd = true;
    screenshot-path = "~/Pictures/Screenshots/screenshot-%Y-%m-%d-%H-%M-%S.png";
    hotkey-overlay.skip-at-startup = true;

    cursor = {
      theme = config.stylix.cursor.name;
      inherit (config.stylix.cursor) size;
    };

    environment = {
      DISPLAY = ":0";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      IN_NIX_SHELL = null;
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "niri";
      CLUTTER_BACKEND = "wayland";
      ANKI_WAYLAND = "1";
      XCURSOR_SIZE = if isThinkpad then "20" else "24";
    };

    spawn-at-startup = [
      {
        command = [
          "${pkgs.bash}/bin/bash"
          "-c"
          "pgrep -f 'niri-auth-float' > /dev/null || exec ${config.home.profileDirectory}/.local/bin/niri-auth-float"
        ];
      }
      {
        command = [
          "dbus-update-activation-environment"
          "--systemd"
          "DISPLAY"
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP"
          "XDG_SESSION_TYPE"
          "XDG_SESSION_DESKTOP"
          "DBUS_SESSION_BUS_ADDRESS"
          "XDG_RUNTIME_DIR"
        ];
      }
      {
        command = [
          "${pkgs.bash}/bin/bash"
          "-c"
          "pgrep -x quickshell > /dev/null || exec ${config.home.profileDirectory}/bin/noctalia-shell"
        ];
      }
      { command = [ "xwayland-satellite" ]; }
      {
        command = [
          "wl-paste"
          "--type"
          "text"
          "--watch"
          "cliphist"
          "store"
        ];
      }
      {
        command = [
          "wl-paste"
          "--type"
          "image"
          "--watch"
          "cliphist"
          "store"
        ];
      }
      {
        command = [
          "${pkgs.wl-clip-persist}/bin/wl-clip-persist"
          "--clipboard"
          "regular"
        ];
      }
    ];

    switch-events = {
      lid-close.action.spawn = [
        "${config.home.profileDirectory}/bin/noctalia-shell"
        "ipc"
        "call"
        "lockScreen"
        "lock"
      ];
    };

    layer-rules = [
      {
        matches = [ { namespace = "^noctalia-overview.*"; } ];
        place-within-backdrop = true;
      }
    ];

    debug = {
      honor-xdg-activation-with-invalid-serial = { };
      wait-for-frame-completion-before-queueing = { };
      disable-direct-scanout = { };
    };
  };
}
