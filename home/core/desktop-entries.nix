{ config, ... }: {
  xdg.desktopEntries = {
    "org.telegram.desktop" = {
      name = "Telegram Desktop";
      exec = "/run/current-system/sw/bin/telegram-desktop -- %U";
      icon = "org.telegram.desktop";
      comment = "Official Telegram Desktop client (firejail-wrapped)";
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
          exec = "/run/current-system/sw/bin/telegram-desktop -quit";
          icon = "application-exit";
        };
      };
    };

    "com.ayugram.desktop" = {
      name = "AyuGram Desktop";
      exec = "/run/current-system/sw/bin/ayugram-desktop -- %U";
      icon = "org.telegram.desktop";
      comment = "AyuGram Telegram client (firejail-wrapped)";
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
        StartupWMClass = "AyuGram";
        DBusActivatable = "true";
        SingleMainWindow = "true";
        Keywords = "tg;chat;im;messaging;messenger;sms;telegram;ayugram;";
      };
      actions = {
        quit = {
          name = "Quit AyuGram";
          exec = "/run/current-system/sw/bin/AyuGram -quit";
          icon = "application-exit";
        };
      };
    };

    "brave-browser" = {
      name = "Brave Web Browser";
      exec = "${config.home.homeDirectory}/.local/bin/brave %U";
      icon = "brave-browser";
      comment = "Fast, private web browser";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeType = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];
    };

    "io.github.celluloid_player.Celluloid" = {
      name = "Celluloid";
      exec = "/run/current-system/sw/bin/celluloid %U";
      icon = "io.github.celluloid_player.Celluloid";
      comment = "GTK video player powered by mpv (firejail-wrapped)";
      categories = [
        "AudioVideo"
        "Video"
        "Player"
        "GTK"
      ];
      mimeType = [
        "video/mp4"
        "video/x-matroska"
        "video/webm"
        "video/mpeg"
        "video/ogg"
        "video/x-msvideo"
        "video/mp2t"
        "video/x-flv"
        "audio/mpeg"
        "audio/ogg"
        "audio/flac"
      ];
    };

  };
}
