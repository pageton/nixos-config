_: {
  xdg.autostart.entries.remmina-applet = {
    enable = false;
  };

  xdg.configFile = {
    "electron-flags.conf".text = ''
      --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecodeLinuxGL
      --ozone-platform-hint=auto
      --disable-gpu-shader-disk-cache
      --enable-zero-copy
    '';
  };

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";
    DISABLE_QT5_COMPAT = "0";
    CALIBRE_USE_DARK_PALETTE = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_ENABLE_HIGHDPI_SCALING = "1";
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1";

    ADBLOCK = "1";
    ASTRO_TELEMETRY_DISABLED = "1";
    AZURE_CORE_COLLECT_TELEMETRY = "0";
    CHECKPOINT_DISABLE = "1";
    DISABLE_OPENCOLLECTIVE = "1";
    DO_NOT_TRACK = "1";
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    GATSBY_TELEMETRY_DISABLED = "1";
    GOTELEMETRY = "off";
    HOMEBREW_NO_ANALYTICS = "1";
    NEXT_TELEMETRY_DISABLED = "1";
    NPM_CONFIG_UPDATE_NOTIFIER = "false";
    NUXT_TELEMETRY_DISABLED = "1";
    POWERSHELL_TELEMETRY_OPTOUT = "1";
    SAM_CLI_TELEMETRY = "0";
    SENTRY_DSN = "";
    STRIPE_CLI_TELEMETRY_OPTOUT = "1";
  };

  services.network-manager-applet.enable = true;
}
