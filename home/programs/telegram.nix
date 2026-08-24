# Second Telegram Desktop (telegramdesktop/tdesktop) — deliberately NOT
# firejail-wrapped, so it runs alongside the sandboxed primary instance
# (nixos/modules/sandboxing.nix + home/core/desktop-entries.nix).
#
# Telegram is single-instance per workdir: pointing this copy at its own
# workdir makes it a fully separate instance (own tdata, settings, accounts)
# instead of just focusing the already-running one.
{ lib, pkgs, ... }:

let
  telegramDesktopSecond = pkgs.writeShellScriptBin "telegram-desktop-second" ''
    set -euo pipefail
    workdir="''${XDG_DATA_HOME:-$HOME/.local/share}/TelegramDesktopSecond"
    mkdir -p "$workdir"
    exec ${lib.getBin pkgs.telegram-desktop}/bin/Telegram -workdir "$workdir" "$@"
  '';
in
{
  home.packages = [ telegramDesktopSecond ];

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
    # firejail-wrapped primary instance's entry.
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
