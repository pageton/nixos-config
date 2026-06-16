# Niri scrollable-tiling Wayland compositor — Home Manager configuration.
{ config, pkgs, ... }: {
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

  programs.niri.settings = {
    outputs = {
      "DP-4" = {
        mode = {
          width = 1920;
          height = 1080;
          refresh = 143.976;
        };
        transform.rotation = 90;
        position = {
          x = 2560;
          y = 0;
        };
        scale = 1;
      };

      "DP-5" = {
        mode = {
          width = 2560;
          height = 1440;
          refresh = 164.835;
        };
        position = {
          x = 0;
          y = 0;
        };
        scale = 1;
        focus-at-startup = true;
      };
    };

    prefer-no-csd = true;
    screenshot-path = "~/Screens/screenshot-%Y-%m-%d-%H-%M-%S.png";
    hotkey-overlay.skip-at-startup = true;

    cursor = {
      theme = config.stylix.cursor.name;
      inherit (config.stylix.cursor) size;
    };

    environment = {
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
      # Prevent Electron/Chromium GPU sandbox contention with niri under load
      ELECTRON_EXTRA_LAUNCH_FLAGS = "--disable-gpu-sandbox";
      # QT_QPA_PLATFORM is set globally in home.nix sessionVariables
      QT_STYLE_OVERRIDE = "kvantum";
      XDG_SCREENSHOTS_DIR = "$HOME/Screens";
    };

    # environment = {
    #   _JAVA_AWT_WM_NONREPARENTING = "1";
    #   IN_NIX_SHELL = null;
    #   QT_QPA_PLATFORM = "wayland;xcb";
    #   QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    #   QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    #   ELECTRON_OZONE_PLATFORM_HINT = "x11";
    #   ELECTRON_EXTRA_LAUNCH_FLAGS = "--disable-gpu-sandbox";
    #   XDG_SESSION_TYPE = "wayland";
    #   XDG_CURRENT_DESKTOP = "niri";
    #   XCURSOR_SIZE = if isThinkpad then "20" else "24";
    # };

    spawn-at-startup = [
      {
        command = [
          "${pkgs.bash}/bin/bash"
          "-c"
          "pgrep -f 'niri-auth-float' > /dev/null || exec ${config.home.profileDirectory}/.local/bin/niri-auth-float"
        ];
      }
      { argv = [ "${config.home.profileDirectory}/bin/noctalia-shell" ]; }
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

    # Debug flags — niri KDL uses nullary nodes, so {} produces a bare flag
    # (e.g. "disable-direct-scanout" not "disable-direct-scanout true").
    debug = {
      honor-xdg-activation-with-invalid-serial = { };
    };
  };
}
