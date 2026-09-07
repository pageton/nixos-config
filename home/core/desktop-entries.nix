_: {
  # NOTE: The Telegram main entry moved to home/programs/telegram.nix (it
  # execs that module's telegram-desktop wrapper: unsandboxed + NVIDIA EGL +
  # GStreamer plugin env). Celluloid below still references
  # /run/current-system/sw/bin/ (firejail-wrapped, requires
  # mySystem.sandboxing.enableWrappedBinaries = true).

  xdg.desktopEntries = {

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
