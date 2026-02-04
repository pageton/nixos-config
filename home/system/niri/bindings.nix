# Keybinding configuration for niri.
{config, ...}: {
  programs.niri.settings.binds = with config.lib.niri.actions;
    {
      # ── Applications ────────────────────────────────────────────
      "Mod+Return".action = spawn "alacritty";
      "Mod+E".action = spawn "thunar";
      "Mod+B".action = spawn "brave";

      # ── Window management ───────────────────────────────────────
      "Mod+Q".action = close-window;
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;
      "Mod+C".action = center-column;
      "Mod+T".action = toggle-column-tabbed-display;
      "Mod+Shift+Space".action = toggle-window-floating;
      "Mod+R".action = switch-preset-column-width;
      "Mod+Shift+R".action = switch-preset-window-height;
      "Mod+Ctrl+Comma".action = consume-window-into-column;
      "Mod+Period".action = expel-window-from-column;

      # ── Focus (vim) ─────────────────────────────────────────────
      "Mod+H".action = focus-column-or-monitor-left;
      "Mod+J".action = focus-window-or-workspace-down;
      "Mod+K".action = focus-window-or-workspace-up;
      "Mod+L".action = focus-column-or-monitor-right;

      # ── Focus (arrows) ──────────────────────────────────────────
      "Mod+Left".action = focus-column-left;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;
      "Mod+Right".action = focus-column-right;

      # ── Move windows (vim) ──────────────────────────────────────
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+J".action = move-window-down-or-to-workspace-down;
      "Mod+Shift+K".action = move-window-up-or-to-workspace-up;
      "Mod+Shift+L".action = move-column-right;

      # ── Move to monitor ─────────────────────────────────────────
      "Mod+Ctrl+H".action = move-column-to-monitor-left;
      "Mod+Ctrl+L".action = move-column-to-monitor-right;

      # ── Resize ──────────────────────────────────────────────────
      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Equal".action = set-column-width "+10%";
      "Mod+Shift+Minus".action = set-window-height "-10%";
      "Mod+Shift+Equal".action = set-window-height "+10%";

      # ── Workspace navigation ────────────────────────────────────
      "Mod+Tab".action = focus-workspace-down;
      "Mod+Shift+Tab".action = focus-workspace-up;

      # ── Mouse scroll workspace switching ────────────────────────
      "Mod+WheelScrollDown" = {
        cooldown-ms = 150;
        action = focus-workspace-down;
      };
      "Mod+WheelScrollUp" = {
        cooldown-ms = 150;
        action = focus-workspace-up;
      };

      # ── Screenshots (no Print key — use Mod+P family) ──────────
      "Mod+P".action.screenshot = {};
      "Mod+Ctrl+P".action.screenshot-screen = {};
      "Mod+Alt+P".action.screenshot-window = {};

      # ── Overview ────────────────────────────────────────────────
      "Mod+D" = {
        repeat = false;
        action = toggle-overview;
      };

      # ── Noctalia shell controls (Quickshell IPC) ─────────────────
      "Mod+Space".action.spawn = ["noctalia-shell" "ipc" "call" "launcher" "toggle"];
      "Mod+N".action.spawn = ["noctalia-shell" "ipc" "call" "notifications" "toggleHistory"];
      "Mod+Comma".action.spawn = ["noctalia-shell" "ipc" "call" "settings" "toggle"];
      "Mod+S".action.spawn = ["noctalia-shell" "ipc" "call" "controlCenter" "toggle"];
      "Mod+X".action.spawn = ["noctalia-shell" "ipc" "call" "sessionMenu" "toggle"];
      "Mod+V".action.spawn = ["noctalia-shell" "ipc" "call" "launcher" "clipboard"];
      "Mod+M".action.spawn = ["noctalia-shell" "ipc" "call" "systemMonitor" "toggle"];
      "Mod+Alt+N".action.spawn = ["noctalia-shell" "ipc" "call" "darkMode" "toggle"];

      # ── Lock screen (Noctalia) ──────────────────────────────────
      "Super+Alt+L".action.spawn = ["noctalia-shell" "ipc" "call" "lockScreen" "lock"];

      # ── System ──────────────────────────────────────────────────
      "Mod+Shift+E".action = quit;
      "Mod+Shift+O".action = power-off-monitors;
      "Mod+Escape" = {
        allow-inhibiting = false;
        action = toggle-keyboard-shortcuts-inhibit;
      };

      # ── Volume (Noctalia OSD, allow when locked) ────────────────
      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action.spawn = ["noctalia-shell" "ipc" "call" "volume" "increase"];
      };
      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action.spawn = ["noctalia-shell" "ipc" "call" "volume" "decrease"];
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action.spawn = ["noctalia-shell" "ipc" "call" "volume" "muteOutput"];
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action.spawn = ["noctalia-shell" "ipc" "call" "volume" "muteInput"];
      };

      # ── Brightness (Noctalia OSD, allow when locked) ───────────
      "XF86MonBrightnessUp" = {
        allow-when-locked = true;
        action.spawn = ["noctalia-shell" "ipc" "call" "brightness" "increase"];
      };
      "XF86MonBrightnessDown" = {
        allow-when-locked = true;
        action.spawn = ["noctalia-shell" "ipc" "call" "brightness" "decrease"];
      };

      # ── Media (Noctalia, allow when locked) ────────────────────
      "XF86AudioPlay" = {
        allow-when-locked = true;
        action.spawn = ["noctalia-shell" "ipc" "call" "media" "playPause"];
      };
      "XF86AudioNext" = {
        allow-when-locked = true;
        action.spawn = ["noctalia-shell" "ipc" "call" "media" "next"];
      };
      "XF86AudioPrev" = {
        allow-when-locked = true;
        action.spawn = ["noctalia-shell" "ipc" "call" "media" "previous"];
      };
    }
    // builtins.listToAttrs (
      builtins.concatLists (
        builtins.genList (
          i: let
            ws = i + 1;
          in [
            {
              name = "Mod+${toString ws}";
              value.action = focus-workspace ws;
            }
            {
              name = "Mod+Shift+${toString ws}";
              value.action.move-column-to-workspace = ws;
            }
          ]
        )
        9
      )
    );
}
