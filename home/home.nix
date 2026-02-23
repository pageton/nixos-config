{
  config,
  homeStateVersion,
  user,
  pkgs,
  pkgsStable,
  lib,
  ...
}: {
  imports = [
    ./secrets
    ./programs
    ./scripts
    ./system
    ./themes/kanagawa.nix
  ];

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = homeStateVersion;
  };

  nixpkgs.config.allowUnfree = true;

  home.packages = let Pkgs = import ./packages {inherit pkgs pkgsStable;}; in Pkgs;

  home.file.".face" = {
    source = ./profile_picture.png;
  };

  xdg.autostart.entries.remmina-applet = {
    enable = false;
  };

  # Global Electron flags for NVIDIA Wayland — fixes scroll glitches and rendering artifacts
  xdg.configFile = {
    "electron-flags.conf".text = ''
      --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecodeLinuxGL
      --ozone-platform-hint=auto
      --disable-gpu-shader-disk-cache
      --enable-zero-copy
    '';
  };

  # Environment variables for session-wide configuration
  home.sessionVariables = {
    # Wayland/Qt integration
    QT_QPA_PLATFORM = "wayland;xcb";
    DISABLE_QT5_COMPAT = "0";
    CALIBRE_USE_DARK_PALETTE = "1";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_ENABLE_HIGHDPI_SCALING = "1";
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1";

    # === Telemetry & tracking opt-outs ===
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

  fonts.fontconfig.enable = true;
  programs.home-manager.enable = true;

  # User services (auto-start tray applets)
  services = {
    network-manager-applet.enable = true;
  };

  # Desktop entries for firejail-wrapped binaries — override store-path .desktop
  # files so app launchers route through the firejail wrapper in PATH.
  xdg.desktopEntries = {
    "org.telegram.desktop" = {
      name = "Telegram Desktop";
      exec = "/run/current-system/sw/bin/telegram-desktop -- %U";
      icon = "org.telegram.desktop";
      comment = "Official Telegram Desktop client (firejail-wrapped)";
      categories = ["Chat" "Network" "InstantMessaging" "Qt"];
      mimeType = ["x-scheme-handler/tg" "x-scheme-handler/tonsite"];
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
    "brave-browser" = {
      name = "Brave Web Browser";
      exec = "/run/current-system/sw/bin/brave %U";
      icon = "brave-browser";
      comment = "Brave Web Browser (firejail-wrapped)";
      categories = ["Network" "WebBrowser"];
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
      categories = ["AudioVideo" "Video" "Player" "GTK"];
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
    "libreoffice-startcenter" = {
      name = "LibreOffice";
      exec = "/run/current-system/sw/bin/libreoffice %U";
      icon = "libreoffice-startcenter";
      comment = "Office suite (firejail-wrapped)";
      categories = ["Office"];
      mimeType = [
        "application/vnd.oasis.opendocument.text"
        "application/vnd.oasis.opendocument.spreadsheet"
        "application/vnd.oasis.opendocument.presentation"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        "application/msword"
        "application/vnd.ms-excel"
        "application/vnd.ms-powerpoint"
        "application/rtf"
      ];
    };
  };

  # Stylix sets GTK theme but not dconf color-scheme key — without this,
  # GTK4/libadwaita apps default to light mode (dark text on dark background).
  gtk = {
    # enable is set by kanagawa.nix (stylix.targets.gtk.enable)
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;
    };
    "org/gnome/desktop/privacy" = {
      remember-recent-files = false;
      recent-files-max-age = 0;
      remove-old-trash-files = true;
      remove-old-temp-files = true;
      old-files-age = 7;
    };
  };

  # Override home-manager's installPackages activation to use `nix profile add`
  # instead of the deprecated `nix profile install`.
  # Upstream fix: https://github.com/nix-community/home-manager/pull/8756
  # TODO: Remove this override once home-manager merges PR #8756
  home.activation.installPackages = lib.mkForce (lib.hm.dag.entryAfter ["writeBoundary"] ''
    function nixReplaceProfile() {
      local oldNix="$(command -v nix)"

      nixProfileRemove 'home-manager-path'

      run $oldNix profile add $1
    }

    if [[ -e ${config.home.profileDirectory}/manifest.json ]] ; then
      INSTALL_CMD="nix profile add"
      INSTALL_CMD_ACTUAL="nixReplaceProfile"
      LIST_CMD="nix profile list"
      REMOVE_CMD_SYNTAX='nix profile remove {number | store path}'
    else
      INSTALL_CMD="nix-env -i"
      INSTALL_CMD_ACTUAL="run nix-env -i"
      LIST_CMD="nix-env -q"
      REMOVE_CMD_SYNTAX='nix-env -e {package name}'
    fi

    if ! $INSTALL_CMD_ACTUAL ${config.home.path} ; then
      echo
      _iError $'Oops, Nix failed to install your new Home Manager profile!\n\nPerhaps there is a conflict with a package that was installed using\n"%s"? Try running\n\n    %s\n\nand if there is a conflicting package you can remove it with\n\n    %s\n\nThen try activating your Home Manager configuration again.' "$INSTALL_CMD" "$LIST_CMD" "$REMOVE_CMD_SYNTAX"
      exit 1
    fi
    unset -f nixReplaceProfile
    unset INSTALL_CMD INSTALL_CMD_ACTUAL LIST_CMD REMOVE_CMD_SYNTAX
  '');
}
