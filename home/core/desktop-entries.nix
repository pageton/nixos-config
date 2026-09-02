_: {
  # NOTE: The Telegram main entry moved to home/programs/telegram.nix (it
  # execs that module's telegram-desktop wrapper: unsandboxed + NVIDIA EGL +
  # GStreamer plugin env). AyuGram/Celluloid below still reference
  # /run/current-system/sw/bin/ (firejail-wrapped, require
  # mySystem.sandboxing.enableWrappedBinaries = true).

  xdg.desktopEntries = {

    "com.ayugram.desktop" = {
      name = "AyuGram Desktop";
      # Same NVIDIA EGL webview fix as the Telegram entry above.
      exec = "env GBM_BACKEND=nvidia-drm __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/10_nvidia.json /run/current-system/sw/bin/ayugram-desktop -- %U";
      icon = "org.telegram.desktop"; # AyuGram is a Telegram fork — reuses the Telegram icon intentionally
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
      # Firejail-wrapped system binary — requires
      # mySystem.sandboxing.enableWrappedBinaries = true (see nixos/modules/sandboxing.nix).
      exec = "/run/current-system/sw/bin/brave %U";
      icon = "brave-browser";
      comment = "Fast, private web browser";
      categories = [
        "Network"
        "WebBrowser"
      ];
      settings = {
        StartupWMClass = "Brave-browser";
      };
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
