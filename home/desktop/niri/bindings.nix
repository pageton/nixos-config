# Keybinding configuration for niri.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # noctalia: auto-launch the shell if it isn't running, then send an IPC msg.
  # v5 IPC is `noctalia msg <command>` (kebab-case single string); v4 was
  # `noctalia-shell ipc call <ns> <method>`. The wrapper preserves the
  # fire-and-forget + auto-start behavior so keybinds work mid-shell-restart.
  noctalia =
    cmd:
    [
      "${pkgs.bash}/bin/bash"
      "-c"
      ''
        if ! ${config.home.profileDirectory}/bin/noctalia msg "$@" >/dev/null 2>&1; then
          ${pkgs.coreutils}/bin/nohup ${config.home.profileDirectory}/bin/noctalia >/dev/null 2>&1 &
          ${pkgs.coreutils}/bin/sleep 0.35
          ${config.home.profileDirectory}/bin/noctalia msg "$@" >/dev/null 2>&1 || true
        fi
      ''
      "bash"
    ]
    ++ (lib.splitString " " cmd);
in
{
  programs.niri.settings.binds = with config.lib.niri.actions; {
    # ── Applications ────────────────────────────────────────────
    "Mod+Return".action.spawn = [
      "alacritty"
      "-e"
      "zellij-tui"
    ];
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

    # ── Screenshots ─────────────────────────────────────────────
    "Mod+P".action.screenshot = { };
    "Mod+Ctrl+P".action.screenshot-screen = { };
    "Mod+Alt+P".action.screenshot-window = { };

    # ── Overview ────────────────────────────────────────────────
    "Mod+D" = {
      repeat = false;
      action = toggle-overview;
    };

    # ── Noctalia v5 shell controls ─────────────────────────────
    # IPC verbs verified from upstream src/ipc + per-service registerIpc calls.
    "Mod+Space".action.spawn = noctalia "panel-toggle launcher";
    "Mod+W".action.spawn = noctalia "panel-toggle launcher"; # v5: no separate windows mode; launcher lists apps + windows
    "Mod+N".action.spawn = noctalia "notification-clear-history";
    "Mod+Comma".action.spawn = noctalia "settings-toggle";
    "Mod+S".action.spawn = noctalia "panel-toggle control-center";
    "Mod+X".action.spawn = noctalia "panel-toggle session";

    # ── Clipboard ──────────────────────────────────────────────────
    # Mod+V (v4 QML clipboard plugin) is deferred — v5 has a native clipboard
    # panel reachable via `panel-toggle clipboard` and the bar widget. Rebind
    # Mod+V to that native panel so the key isn't dead.
    "Mod+V".action.spawn = noctalia "panel-toggle clipboard";

    # Mod+M (v4 systemMonitor toggle): v5 has no dedicated system-monitor panel;
    # route to the control center where system metrics live.
    "Mod+M".action.spawn = noctalia "panel-toggle control-center";
    "Mod+Alt+N".action.spawn = noctalia "theme-mode-toggle";

    # ── Lock screen ─────────────────────────────────────────────
    # session lock (verified: src/shell/session/session_ipc.cpp).
    "Super+Alt+L".action.spawn = noctalia "session lock";

    # ── System ──────────────────────────────────────────────────
    "Mod+Shift+E".action = quit;
    "Mod+Shift+O".action = power-off-monitors;
    "Mod+Escape" = {
      allow-inhibiting = false;
      action = toggle-keyboard-shortcuts-inhibit;
    };

    # ── Volume (allow when locked) ──────────────────────────────
    "XF86AudioRaiseVolume" = {
      allow-when-locked = true;
      action.spawn = noctalia "volume-up";
    };
    "XF86AudioLowerVolume" = {
      allow-when-locked = true;
      action.spawn = noctalia "volume-down";
    };
    "XF86AudioMute" = {
      allow-when-locked = true;
      action.spawn = noctalia "volume-mute";
    };
    "XF86AudioMicMute" = {
      allow-when-locked = true;
      action.spawn = noctalia "mic-mute";
    };

    # ── Brightness (allow when locked) ─────────────────────────
    "XF86MonBrightnessUp" = {
      allow-when-locked = true;
      action.spawn = noctalia "brightness-up";
    };
    "XF86MonBrightnessDown" = {
      allow-when-locked = true;
      action.spawn = noctalia "brightness-down";
    };

    # ── Media (allow when locked) ──────────────────────────────
    "XF86AudioPlay" = {
      allow-when-locked = true;
      action.spawn = noctalia "media play-pause";
    };
    "XF86AudioNext" = {
      allow-when-locked = true;
      action.spawn = noctalia "media next";
    };
    "XF86AudioPrev" = {
      allow-when-locked = true;
      action.spawn = noctalia "media previous";
    };
  };
}
