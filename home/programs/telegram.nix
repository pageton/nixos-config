# Telegram Desktop — unsandboxed main instance + separate second instance.
#
# The primary Telegram was removed from firejail wrapping (2026-08-29,
# nixos/modules/sandboxing.nix). nixpkgs telegram-desktop only ships the
# `Telegram` binary, so this module provides the `telegram-desktop` command
# (CLI + scripts), matching the desktop entry in home/core/desktop-entries.nix.
#
# Telegram is single-instance per workdir: the second wrapper points at its
# own workdir, making it a fully separate instance (own tdata, settings,
# accounts) instead of just focusing the already-running one.
{ lib, pkgs, ... }:

let
  # NVIDIA EGL fix for mini apps (WebKitGTK webview) — see
  # home/core/desktop-entries.nix for the rationale.
  nvidiaEglEnv = ''
    export GBM_BACKEND=nvidia-drm
    export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json
  '';

  # tdesktop's store binary is a plain ELF with no GStreamer wrapper, so
  # media playback dies with "GStreamer element appsink not found" unless the
  # plugin path is provided here.
  gstPluginPath = lib.makeSearchPath "lib/gstreamer-1.0" (
    with pkgs.gst_all_1;
    [
      gstreamer
      gst-plugins-base # appsink/appsrc
      gst-plugins-good
      gst-plugins-bad
      gst-libav
    ]
  );
  gstEnv = ''
    export GST_PLUGIN_PATH="${gstPluginPath}:''${GST_PLUGIN_PATH:-}"
  '';

  telegramDesktop = pkgs.writeShellScriptBin "telegram-desktop" ''
    set -euo pipefail
    ${nvidiaEglEnv}
    ${gstEnv}
    exec ${lib.getBin pkgs.telegram-desktop}/bin/Telegram "$@"
  '';

  telegramDesktopSecond = pkgs.writeShellScriptBin "telegram-desktop-second" ''
    set -euo pipefail
    workdir="''${XDG_DATA_HOME:-$HOME/.local/share}/TelegramDesktopSecond"
    mkdir -p "$workdir"
    ${nvidiaEglEnv}
    ${gstEnv}
    exec ${lib.getBin pkgs.telegram-desktop}/bin/Telegram -workdir "$workdir" "$@"
  '';
in
{
  home.packages = [
    telegramDesktop
    telegramDesktopSecond
  ];

  xdg.desktopEntries."org.telegram.desktop" = {
    name = "Telegram Desktop";
    exec = "${telegramDesktop}/bin/telegram-desktop -- %U";
    icon = "org.telegram.desktop";
    comment = "Official Telegram Desktop client (unsandboxed)";
    categories = [
      "Chat"
      "Network"
      "InstantMessaging"
      "Qt"
    ];
    mimeType = [
      "x-scheme-handler/tg"
      "x-scheme-handler/tonsite"
    ];
    settings = {
      StartupWMClass = "TelegramDesktop";
      DBusActivatable = "true";
      SingleMainWindow = "true";
      Keywords = "tg;chat;im;messaging;messenger;sms;tdesktop;";
    };
    actions = {
      quit = {
        name = "Quit Telegram";
        exec = "${telegramDesktop}/bin/telegram-desktop -quit";
        icon = "application-exit";
      };
    };
  };

  xdg.desktopEntries."org.telegram.desktop.second" = {
    name = "Telegram Desktop Second";
    exec = "${telegramDesktopSecond}/bin/telegram-desktop-second -- %U";
    icon = "org.telegram.desktop";
    comment = "Second official Telegram Desktop client (unsandboxed, separate profile)";
    categories = [
      "Chat"
      "Network"
      "InstantMessaging"
      "Qt"
    ];
    # No mimeType on purpose: tg:// and tonsite:// links stay bound to the
    # primary instance's entry (home/core/desktop-entries.nix).
    settings = {
      StartupWMClass = "TelegramDesktop";
      SingleMainWindow = "true";
      Keywords = "tg;chat;im;messaging;messenger;sms;tdesktop;second;";
    };
    actions = {
      quit = {
        name = "Quit Telegram Second";
        exec = "${telegramDesktopSecond}/bin/telegram-desktop-second -quit";
        icon = "application-exit";
      };
    };
  };
}
