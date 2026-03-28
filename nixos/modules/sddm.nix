# SDDM is a display manager for X11 and Wayland
{
  lib,
  pkgs,
  config,
  ...
}:
let
  foreground = lib.attrByPath [ "lib" "stylix" "colors" "base05" ] "DCD7BA" config;
  sddmBackground = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master/cat-vibin.png";
    sha256 = "sha256-ERZ4sAGhkaBM/tMBPfxeY5dF6xs61i9xXy1z/ovtJr8=";
  };
  sddm-astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "pixel_sakura";
    themeConfig = {
      HeaderTextColor = "#${foreground}";
      DateTextColor = "#${foreground}";
      TimeTextColor = "#${foreground}";
      LoginFieldTextColor = "#${foreground}";
      PasswordFieldTextColor = "#${foreground}";
      UserIconColor = "#${foreground}";
      PasswordIconColor = "#${foreground}";
      WarningColor = "#${foreground}";
      LoginButtonBackgroundColor = "#${foreground}";
      SystemButtonsIconsColor = "#${foreground}";
      SessionButtonTextColor = "#${foreground}";
      VirtualKeyboardButtonTextColor = "#${foreground}";
      DropdownBackgroundColor = "#${foreground}";
      HighlightBackgroundColor = "#${foreground}";
      Background = toString sddmBackground;
    };
  };
in
{
  services.displayManager = {
    sddm = {
      package = pkgs.kdePackages.sddm;
      extraPackages = [ sddm-astronaut ];
      enable = true;
      wayland.enable = true;
      # NVIDIA + weston can crash greeter; use kwin as SDDM compositor.
      wayland.compositor = "kwin";
      theme = "sddm-astronaut-theme";
      settings = {
        Wayland.SessionDir = "${pkgs.niri-stable}/share/wayland-sessions";
      };
    };

    defaultSession = lib.mkDefault "niri";
  };

  # Ensure only one display manager is active.
  services.greetd.enable = lib.mkForce false;

  environment.systemPackages = [ sddm-astronaut ];
}
