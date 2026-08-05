# Keybinding configuration for niri.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Send a DMS IPC command, launching the shell first if it isn't running yet.
  # Mirrors the old noctalia wrapper: try the IPC call; on failure, start DMS in
  # the background, briefly wait, then retry. Idempotent and safe to fire from
  # keybindings that may land before the shell is up at session start.
  dms =
    cmd:
    [
      "${pkgs.bash}/bin/bash"
      "-c"
      ''
        if ! ${config.home.profileDirectory}/bin/dms ipc call "$@" >/dev/null 2>&1; then
          ${pkgs.coreutils}/bin/nohup ${config.home.profileDirectory}/bin/dms run >/dev/null 2>&1 &
          ${pkgs.coreutils}/bin/sleep 0.35
          ${config.home.profileDirectory}/bin/dms ipc call "$@" >/dev/null 2>&1 || true
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
    # NOTE: DMS's own niri module binds Mod+P to notepad; we keep Mod+P as
    # screenshot (preserves the existing binding) and skip notepad.
    "Mod+P".action.screenshot = { };
    "Mod+Ctrl+P".action.screenshot-screen = { };
    "Mod+Alt+P".action.screenshot-window = { };

    # ── Overview ────────────────────────────────────────────────
    "Mod+D" = {
      repeat = false;
      action = toggle-overview;
    };

    # ── DankMaterialShell controls ──────────────────────────────
    # IPC targets verified against DMS docs (dms ipc call <target> <action>).
    "Mod+Space".action.spawn = dms "spotlight toggle"; # app launcher
    "Mod+W".action.spawn = dms "spotlight toggle"; # no separate windows mode in DMS
    "Mod+N".action.spawn = dms "notifications toggle";
    "Mod+Comma".action.spawn = dms "settings toggle";
    "Mod+S".action.spawn = dms "control-center toggle";
    "Mod+X".action.spawn = dms "powermenu toggle"; # was sessionMenu
    "Mod+V".action.spawn = dms "clipboard toggle"; # was launcher clipboard
    "Mod+M".action.spawn = dms "processlist toggle"; # was systemMonitor
    "Mod+Alt+N".action.spawn = dms "theme toggle"; # was darkMode

    # ── Lock screen ─────────────────────────────────────────────
    "Super+Alt+L".action.spawn = dms "lock lock";

    # ── System ──────────────────────────────────────────────────
    "Mod+Shift+E".action = quit;
    "Mod+Shift+O".action = power-off-monitors;
    "Mod+Escape" = {
      allow-inhibiting = false;
      action = toggle-keyboard-shortcuts-inhibit;
    };

    # ── Volume (allow when locked) ──────────────────────────────
    # DMS audio: increment/decrement take a step arg; mute toggles output.
    "XF86AudioRaiseVolume" = {
      allow-when-locked = true;
      action.spawn = dms "audio increment 5";
    };
    "XF86AudioLowerVolume" = {
      allow-when-locked = true;
      action.spawn = dms "audio decrement 5";
    };
    "XF86AudioMute" = {
      allow-when-locked = true;
      action.spawn = dms "audio mute";
    };
    "XF86AudioMicMute" = {
      allow-when-locked = true;
      action.spawn = dms "audio micmute";
    };

    # ── Brightness (allow when locked) ─────────────────────────
    # DMS brightness: increment/decrement take <step> and a trailing "" arg
    # (matches DMS's own niri module binding shape).
    "XF86MonBrightnessUp" = {
      allow-when-locked = true;
      action.spawn = dms "brightness increment 5 \"\"";
    };
    "XF86MonBrightnessDown" = {
      allow-when-locked = true;
      action.spawn = dms "brightness decrement 5 \"\"";
    };

    # ── Media (allow when locked) ──────────────────────────────
    "XF86AudioPlay" = {
      allow-when-locked = true;
      action.spawn = dms "mpris playPause";
    };
    "XF86AudioNext" = {
      allow-when-locked = true;
      action.spawn = dms "mpris next";
    };
    "XF86AudioPrev" = {
      allow-when-locked = true;
      action.spawn = dms "mpris previous";
    };
  };
}
