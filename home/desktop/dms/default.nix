# DankMaterialShell — Go + Quickshell desktop shell for niri.
# Replaces Noctalia. Provides bar, launcher (spotlight), notifications,
# control center, lock screen, power menu, clipboard, OSD, and dynamic theming.
#
# Config reference: ~/.config/DankMaterialShell/settings.json
# State reference: ~/.local/state/DankMaterialShell/session.json
# IPC: `dms ipc call <target> <action>` (e.g. `dms ipc call spotlight toggle`)
{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:
let
  # Profile image shown inside the DMS shell (panel/greeter avatar). Installed
  # to a stable path so DMS's stored reference survives reinstalls and doesn't
  # depend on the repo working tree.
  profileImage = ../../assets/profile_picture.png;
  profileImageDest = "${config.home.homeDirectory}/.local/share/DankMaterialShell/profile.png";
  # Single source of truth for the wallpaper: the stylix image (set in
  # home/themes/stylix.nix from the nix-wallpaper package). DMS derives its
  # matugen color palette from this.
  wallpaper = toString config.stylix.image;
  # Desktop has no backlight to control; only show the brightness slider on
  # laptops (thinkpad). Matches the old Noctalia bar's isThinkpad Brightness.
  isDesktop = hostname == "desktop";
in
{
  imports = [ ./packages.nix ];

  services.status-notifier-watcher.enable = true;

  programs.dank-material-shell = {
    enable = true;

    # Let DMS manage itself via systemd so it restarts on failure and on
    # `nh home switch`. Target follows the wayland session.
    systemd.enable = true;

    # Minimal confirmed settings. DMS ships sensible defaults; expand via the
    # in-app Settings UI (`Mod+Comma`) rather than guessing the full schema here.
    # The HM module writes ~/.config/DankMaterialShell/settings.json from this.
    settings = {
      # Follow the system typography selected by Stylix instead of DMS defaults.
      fontFamily = config.stylix.fonts.sansSerif.name;
      monoFontFamily = config.stylix.fonts.monospace.name;

      # Show application icons in the workspace switcher (like Noctalia's
      # `showApplications = true`). DMS defaults this off.
      showWorkspaceApps = true;
      # Show ALL app icons per workspace, not just the first 3. DMS caps this at
      # 3 by default; setting it high effectively means unlimited. NOTE: 0 here
      # does NOT mean unlimited — the renderer uses Math.min(count, value), so 0
      # would hide every icon.
      maxWorkspaceIcons = 50;
      # Slightly enlarge workspace app icons (offset added to the bar's base
      # icon size). Default is 0.
      workspaceAppIconSizeOffset = 4;
      # Keep the focused workspace pill unfilled so application icons retain
      # visual priority; the border provides the focus indicator.
      workspaceColorMode = "none";
      workspaceFocusedBorderEnabled = true;
      # Don't show the battery percentage (battery widget is also removed from
      # the bar above; this covers the control-center / popout display).
      showBatteryPercent = false;
      # Center the bar's centerWidgets geometrically (true center of the bar)
      # rather than between the left/right sections. Default is "index".
      centeringMode = "geometric";

      # Control-center tile layout. Order in the list = display order. Each
      # tile's `width` is a percentage of the control-center width (50 =
      # half-width, two-per-row). The brightnessSlider is only useful on
      # laptops (desktop has no backlight), so it's omitted when isDesktop.
      # NOTE: brightnessSlider's instanceId/deviceName are runtime-populated by
      # DMS (it picks the monitor) — not set here.
      controlCenterWidgets =
        let
          mk = id: {
            inherit id;
            enabled = true;
            width = 50;
          };
          # Tiles every host gets. inputVolumeSlider = mic input level.
          # idleInhibitor = caffeine (keep-awake). builtin_tailscale = Tailscale
          # VPN status/toggle (uses the tailscale system service).
          common = [
            (mk "volumeSlider")
            (mk "inputVolumeSlider")
            (mk "wifi")
            (mk "bluetooth")
            (mk "audioOutput")
            (mk "audioInput")
            (mk "nightMode")
            (mk "darkMode")
            (mk "idleInhibitor")
            (mk "builtin_tailscale")
          ];
          # Insert brightnessSlider after inputVolumeSlider on non-desktop.
          withBrightness = lib.take 2 common ++ [ (mk "brightnessSlider") ] ++ lib.drop 2 common;
        in
        if isDesktop then common else withBrightness;

      # Bar layout — matches the live DMS config (rearranged via Settings UI).
      # The IPC `settings set barConfigs` path rejects nested-array edits, so
      # this is set declaratively here. battery widget only on non-desktop.
      barConfigs = [
        {
          id = "default";
          name = "Main Bar";
          enabled = true;
          position = 0;
          screenPreferences = [ "all" ];
          showOnLastDisplay = true;
          leftWidgets = [
            {
              id = "clock";
              enabled = true;
              clockCompactMode = false;
            }
            "cpuUsage"
            "cpuTemp"
            "memUsage"
            "diskUsage"
            {
              id = "focusedWindow";
              enabled = true;
              focusedWindowSize = 0;
              focusedWindowCompactMode = true;
            }
            {
              id = "music";
              enabled = true;
            }
          ];
          centerWidgets = [
            {
              id = "workspaceSwitcher";
              enabled = true;
            }
          ];
          rightWidgets = [
            "keyboard_layout_name"
            "systemTray"
            "notepadButton"
            "clipboard"
          ]
          ++ lib.optional (!isDesktop) "battery"
          ++ [
            {
              id = "controlCenterButton";
              enabled = true;
              showBrightnessIcon = false;
              showBrightnessPercent = false;
              showMicIcon = false;
              showMicPercent = false;
              showIdleInhibitorIcon = true;
              controlCenterGroupOrder = [
                "network"
                "vpn"
                "bluetooth"
                "audio"
                "idleInhibitor"
                "microphone"
                "brightness"
                "battery"
                "printer"
                "screenSharing"
                "doNotDisturb"
              ];
            }
            "notificationButton"
          ];
          spacing = 4;
          innerPadding = 4;
          bottomGap = 0;
          # Keep the floating edge spacing when a window is maximized.
          # Let DMS remove Niri gaps and borders independently on each output
          # when that output contains a maximized window.
          maximizeDetection = true;
          transparency = 1.0;
          widgetTransparency = 1.0;
        }
      ];
    };

    # Keep DMS's native clipboard history until entries are removed manually.
    clipboardSettings = {
      autoClearDays = 0;
      clearAtStartup = false;
    };

    # session.json holds DMS's *authoritative* runtime wallpaper state
    # (the `wallpaperPath` key the shell actually reads at startup). We pin it
    # to the stylix wallpaper so DMS, stylix, and the greeter all share one
    # background, declared in one place (home/themes/stylix.nix).
    session.wallpaperPath = wallpaper;
  };

  # ── Profile image ──────────────────────────────────────────────────────
  # DMS exposes no declarative option for the panel avatar; it stores only a
  # path reference via the `profile` IPC target (in-memory only — lost on every
  # service restart). We install the image to a stable location and re-apply it
  # via a systemd ExecStartPost drop-in so it survives switches, restarts, and
  # reboots. See the dms.service drop-in below.
  home.file.".local/share/DankMaterialShell/profile.png".source = profileImage;

  # ── Re-apply runtime state after every dms.service start ───────────────
  # The profile image lives only in DMS's in-memory state; restarting the
  # service (switch, manual restart, reboot) wipes it. An ExecStartPost drop-in
  # fires after `dms run` is up, when the IPC socket is ready — more reliable
  # than a home.activation script (which races the service startup). A small
  # retry loop verifies the applied value because early IPC calls can exit zero
  # before the profile target is registered without changing the image.
  systemd.user.services.dms.Service.ExecStartPost =
    let
      dms = lib.getExe config.programs.dank-material-shell.package;
      syncScript = pkgs.writeShellScript "dms-sync-state" ''
        for _attempt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
          ${dms} ipc call profile setImage \
            ${lib.escapeShellArg profileImageDest} >/dev/null 2>&1 || true
          current_image="$(${dms} ipc call profile getImage 2>/dev/null || true)"
          if [ "$current_image" = ${lib.escapeShellArg profileImageDest} ]; then
            break
          fi
          ${pkgs.coreutils}/bin/sleep 0.25
        done
        ${dms} ipc call wallpaper set ${lib.escapeShellArg wallpaper} >/dev/null 2>&1 || true
      '';
    in
    syncScript;
}
