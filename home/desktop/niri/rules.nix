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
          app-id = "^librewolf$";
          title = "^Picture-in-Picture$";
        }
      ];
      open-floating = true;
      open-focused = true;
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
      open-focused = true;
    }

    # Floating: browser extension popups (Bitwarden, etc.)
    # app-id format: brave-<extension_id>-<Profile> or librewolf-<extension_id>-<Profile>
    {
      matches = [
        { app-id = "^brave-[a-z]{32}"; }
        { app-id = "^librewolf-[a-z]{32}"; }
      ];
      open-floating = true;
      open-focused = true;
      default-column-width.fixed = 380;
      default-window-height.fixed = 580;
    }

    # Floating: mini app windows (app-id agnostic — Telegram, wrappers, etc.)
    {
      matches = [ { title = "^Mini App:.*$"; } ];
      open-floating = true;
      open-focused = true;
      default-column-width.fixed = 400;
      default-window-height.fixed = 600;
    }

    # Floating: Telegram secondary windows, centered on screen
    # - Article (Instant View), Editing (edit-in-window), and separate chat windows
    #   ("<chat> @ <account> (<id>)" — the " @ " separates them from the main window).
    # - Official-build Qt windows append a per-workdir hash to the app-id
    #   ("org.telegram.desktop._<md5>"), so all Telegram app-ids here
    #   prefix-match; the GTK file dialog still reports the plain form
    #   (app-id derives from the ELF name in home/programs/telegram.nix).
    # No default-floating-position → niri centers new floats by default
    # (default-floating-position x/y are PIXELS from the relative-to corner, so
    #  any value we set can only anchor to a corner/edge, never true center).
    # niri has no window pinning — floats render above tiled windows on their workspace.
    {
      matches = [
        {
          app-id = "^org\\.telegram\\.desktop";
          title = "^Article\\b";
        }
        {
          app-id = "^org\\.telegram\\.desktop";
          title = "^Editing\\b";
        }
        {
          app-id = "^org\\.telegram\\.desktop";
          title = " @ .*\\(\\d+\\)$";
        }
        { app-id = "^\\.Telegram-wrapped$"; }
      ];
      open-floating = true;
      open-focused = true;
    }

    # Telegram file dialog ("Choose Files" — send/receive picker). With the
    # renamed ELF (home/programs/telegram.nix) the native GTK dialog reports
    # org.telegram.desktop; the .Telegram-wrapped match is a fallback. No
    # default-floating-position → opens centered like the other Telegram
    # floats; size pinned to its natural 958x790; takes focus on open.
    {
      matches = [
        {
          app-id = "^org\\.telegram\\.desktop";
          title = "^Choose Files";
        }
        {
          app-id = "^\\.Telegram-wrapped$";
          title = "^Choose Files";
        }
      ];
      open-floating = true;
      open-focused = true;
      default-column-width.fixed = 958;
      default-window-height.fixed = 790;
    }

    # Telegram main + call windows, both as centered floats. The main window
    # is titled "<account> (<id>)"; calls carry the bare chat name. Pop-outs
    # ("<chat> @ <account> (<id>)"), Instant View, editors, mini apps, and
    # the file dialog have their own markers and rules, so they're excluded
    # here. Applies at window-open time — already-open windows keep their
    # state (toggle manually with Mod+Shift+Space).
    {
      matches = [ { app-id = "^org\\.telegram\\.desktop"; } ];
      excludes = [
        { title = " @ "; } # pop-out chats (own rule above)
        { title = "^(Article|Editing)\\b"; }
        { title = "^Mini App:"; }
        { title = "^Choose Files"; }
      ];
      open-floating = true;
      open-focused = true;
    }

    # xdg-desktop-portal FileChooser dialogs ("Open Files", "Save Files", …).
    # The window belongs to the portal process, so the app-id is stable
    # regardless of which app opened it; portals.conf routes only
    # FileChooser to the gtk portal, so every window it spawns is a chooser.
    # Same treatment as the Telegram dialog: centered float at 958x790.
    {
      matches = [ { app-id = "^xdg-desktop-portal-gtk$"; } ];
      open-floating = true;
      open-focused = true;
      default-column-width.fixed = 958;
      default-window-height.fixed = 790;
    }

    # Floating: Android Emulator windows, docked top-right at their current position
    # (NOT centered). Offsets are working-area px: noctalia bar reserves 40px top, so
    # output y=58 → y=18. Phone window 76px from right edge, side toolbar 6px.
    {
      matches = [
        {
          app-id = "^Emulator$";
          title = "^Android Emulator";
        }
      ];
      open-floating = true;
      open-focused = true;
      default-floating-position = {
        x = 76;
        y = 18;
        relative-to = "top-right";
      };
    }
    {
      matches = [
        {
          app-id = "^Emulator$";
          title = "^Emulator$";
        }
      ];
      open-floating = true;
      open-focused = true;
      default-floating-position = {
        x = 6;
        y = 18;
        relative-to = "top-right";
      };
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
      open-focused = true;
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
      matches = [ { app-id = "^librewolf$"; } ];
      opacity = 0.95;
    }

    # C&C Yuri's Revenge client
    {
      matches = [ { app-id = "^clientdx\\.exe$"; } ];
      open-floating = true;
      open-focused = true;
    }
  ];
}
