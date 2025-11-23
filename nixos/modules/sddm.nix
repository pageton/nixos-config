# SDDM configuration (login screen).

{ pkgs
, lib
, ...
}:
let
  sddmBackground = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master/cat-vibin.png";
    sha256 = "sha256-Hg27Gp4JBrYIC5B1Uaz8QkUskwD3pBhgEwE1FW7VBYo=";
  };
  sddm-astronaut = pkgs.sddm-astronaut.override {
    embeddedTheme = "pixel_sakura";
    themeConfig =
      if lib.hasSuffix "sakura_static.png" sddmBackground then
        { }
      else if lib.hasSuffix "studio.png" sddmBackground then
        {
          Background = pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/anotherhadi/nixy-wallpapers/refs/heads/main/wallpapers/studio.gif";
            sha256 = "sha256-qySDskjmFYt+ncslpbz0BfXiWm4hmFf5GPWF2NlTVB8=";
          };
          HeaderTextColor = "#cdd6f4";
          DateTextColor = "#cdd6f4";
          TimeTextColor = "#cdd6f4";
          LoginFieldTextColor = "#cdd6f4";
          PasswordFieldTextColor = "#cdd6f4";
          UserIconColor = "#cdd6f4";
          PasswordIconColor = "#cdd6f4";
          WarningColor = "#cdd6f4";
          LoginButtonBackgroundColor = "#cdd6f4";
          SystemButtonsIconsColor = "#cdd6f4";
          SessionButtonTextColor = "#cdd6f4";
          VirtualKeyboardButtonTextColor = "#cdd6f4";
          DropdownBackgroundColor = "#cdd6f4";
          HighlightBackgroundColor = "#cdd6f4";
        }
      else
        {
          Background = "${toString sddmBackground}";
          HeaderTextColor = "#cdd6f4";
          DateTextColor = "#cdd6f4";
          TimeTextColor = "#cdd6f4";
          LoginFieldTextColor = "#cdd6f4";
          PasswordFieldTextColor = "#cdd6f4";
          UserIconColor = "#cdd6f4";
          PasswordIconColor = "#cdd6f4";
          WarningColor = "#cdd6f4";
          LoginButtonBackgroundColor = "#cdd6f4";
          SystemButtonsIconsColor = "#cdd6f4";
          SessionButtonTextColor = "#cdd6f4";
          VirtualKeyboardButtonTextColor = "#cdd6f4";
          DropdownBackgroundColor = "#cdd6f4";
          HighlightBackgroundColor = "#cdd6f4";
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
      theme = "sddm-astronaut-theme";
      settings = {
        Wayland.SessionDir = "${pkgs.hyprland}/share/wayland-sessions";
      };
    };
  };

  environment.systemPackages = [ sddm-astronaut ];
}
