{ config, ... }:
let
  inherit (config.theme) active-opacity inactive-opacity rounding;
  r = rounding * 1.0;
in
{
  programs.niri.settings.window-rules = [
    # Global: rounded corners + active opacity
    {
      geometry-corner-radius = {
        top-left = r;
        top-right = r;
        bottom-left = r;
        bottom-right = r;
      };
      clip-to-geometry = true;
      draw-border-with-background = false;
      opacity = active-opacity;
    }

    # Inactive opacity
    {
      matches = [ { is-focused = false; } ];
      opacity = inactive-opacity;
    }

    # Floating: PiP windows
    {
      matches = [
        {
          app-id = "^firefox$";
          title = "^Picture-in-Picture$";
        }
        {
          app-id = "^zen$";
          title = "^Picture-in-Picture$";
        }
      ];
      open-floating = true;
      default-floating-position = {
        x = 32;
        y = 32;
        relative-to = "bottom-right";
      };
      default-column-width.fixed = 480;
      default-window-height.fixed = 270;
    }

    # Floating: dialogs and utilities
    {
      matches = [
        { app-id = "^pavucontrol$"; }
        { app-id = "^blueman-manager$"; }
        { app-id = "^nm-connection-editor$"; }
        { app-id = "^gnome-calculator$"; }
        { title = "^Open File$"; }
        { title = "^Save File$"; }
      ];
      open-floating = true;
    }

    # Floating: Brave extension popups (Bitwarden, etc.)
    # app-id format: brave-<extension_id>-<Profile>
    {
      matches = [ { app-id = "^brave-[a-z]{32}"; } ];
      open-floating = true;
      default-floating-position = {
        x = -0.5;
        y = -0.5;
        relative-to = "bottom-right";
      };
      default-column-width.fixed = 380;
      default-window-height.fixed = 580;
    }

    # Floating: mini app windows (app-id agnostic — Telegram, wrappers, etc.)
    {
      matches = [ { title = "^Mini App:.*$"; } ];
      open-floating = true;
      default-floating-position = {
        x = -0.5;
        y = -0.5;
        relative-to = "bottom-right";
      };
      default-column-width.fixed = 400;
      default-window-height.fixed = 600;
    }

    # Floating: browser auth/OAuth popups (title-based, language-stable keywords)
    {
      matches = [
        # Google sign-in — "Google Accounts" / "حسابات Google" / "Google-Konto"
        { title = ".*Google\\s+[Aa]ccounts.*"; }
        { title = ".*حسابات\\s+Google.*"; }
        { title = ".*Google\\s*[-–]\\s*[Kk]onto.*"; }
        # GitHub OAuth
        { title = ".*[Ss]ign in to [Gg]it[Hh]ub.*"; }
        { title = ".*[Aa]uthorize .* - [Gg]it[Hh]ub.*"; }
        # Microsoft sign-in
        { title = ".*[Ss]ign in to your [Mm]icrosoft.*"; }
        # Generic OAuth authorization
        { title = ".*[Aa]uthorize\\s+.+\\s+-\\s+.+"; }
        { title = ".*[Aa]uthorization [Rr]equest.*"; }
        # Bitwarden vault
        { title = ".*[Bb]itwarden.*[Vv]ault.*"; }
      ];
      open-floating = true;
    }

    # Block password managers from screencasts
    {
      matches = [
        { app-id = "^org\\.keepassxc\\.KeePassXC$"; }
        { app-id = "^Bitwarden$"; }
      ];
      block-out-from = "screencast";
    }

    # Terminal transparency
    {
      matches = [
        { app-id = "^Alacritty$"; }
        { app-id = "^kitty$"; }
        { app-id = "^foot$"; }
      ];
      opacity = 0.95;
      draw-border-with-background = false;
    }

    # Browser transparency
    {
      matches = [ { app-id = "^zen$"; } ];
      opacity = 0.95;
    }

    # C&C Yuri's Revenge client
    {
      matches = [ { app-id = "^clientdx\\.exe$"; } ];
      open-floating = true;
    }
  ];
}
