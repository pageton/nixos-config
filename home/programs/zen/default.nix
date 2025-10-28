# Zen Browser configuration

{ inputs, ... }:

{
  imports = [ inputs.zen-browser.homeModules.default ];

  programs.zen-browser = {
    enable = true;

    # Enhanced policies for privacy, security, and productivity
    policies = {
      # Disable telemetry and data collection
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFeedbackCommands = true;
      DisableFirefoxAccounts = true;

      # Enhanced privacy settings
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
        Social = true;
      };

      # Security enhancements
      DisableAppUpdate = true;
      DontCheckDefaultBrowser = true;
      DisableSafeMode = true;
      DisableDeveloperTools = false; # Keep dev tools enabled for development

      # Login and autofill settings
      OfferToSaveLogins = false;
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      PasswordManagerEnabled = false; # Use external password manager

      # Remove default bookmarks and customize
      NoDefaultBookmarks = true;
      DontUseDownloadDir = false;
      DownloadDirectory = "\${home}/Downloads";

      # HTTPS enforcement
      HTTPSOnlyMode = "force_enhanced";
      AutomaticHttpsRewrites = true;

      # Essential Extensions - Organized by category
      ExtensionSettings = {
        # 🔒 Privacy & Security
        "adguardadblocker@adguard.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/adguard-adblocker/latest.xpi";
          installation_mode = "force_installed";
        };

        "{74145f27-f039-47ce-a470-a662b129930a}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi";
          installation_mode = "force_installed";
        };

        "addon@darkreader.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          installation_mode = "force_installed";
        };

        # 🔑 Password & Security
        "KeeperFFStoreExtension@KeeperSecurityInc" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4598916/keeper_password_manager-17.3.0_NFxaSRD.xpi";
          installation_mode = "force_installed";
        };

        # 🛠️ Development Tools
        "{c45c406e-ab73-11d8-be73-000a95be3b12}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4306323/web_developer-3.0.1.xpi";
          installation_mode = "force_installed";
        };

        "{c3c10168-4186-445c-9c5b-63f12b8e2c87}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/cookie-editor/latest.xpi";
          installation_mode = "force_installed";
        };

        "{16a49f65-1369-4839-a5ef-db2581e08b16}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/3736573/json_lite-21.3.0.xpi";
          installation_mode = "force_installed";
        };

        "@react-devtools" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4432990/react_devtools-6.1.1.xpi";
          installation_mode = "force_installed";
        };

        # 🎨 Design & Media
        "{6AC85730-7D0F-4de0-B3FA-21142DD85326}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/colorzilla/latest.xpi";
          installation_mode = "force_installed";
        };

        # 🔍 Analysis & SEO
        "wappalyzer@crunchlabz.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/wappalyzer/latest.xpi";
          installation_mode = "force_installed";
        };

        "amptra@keepa.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepa/latest.xpi";
          installation_mode = "force_installed";
        };

        # 🛡️ User Agent & Privacy
        "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4497925/user_agent_string_switcher-0.6.5.1.xpi";
          installation_mode = "force_installed";
        };

        # 🔎 Search & Navigation
        "jid1-ZAdIEUB7XOzOJw@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4540706/duckduckgo_for_firefox-2025.7.23.xpi";
          installation_mode = "force_installed";
        };

        # 📺 Media Enhancement
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4541835/sponsorblock-5.14.xpi";
          installation_mode = "force_installed";
        };

        "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4371820/return_youtube_dislikes-3.0.0.18.xpi";
          installation_mode = "force_installed";
        };

        # 🐙 Development Platforms
        "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4563040/refined_github-25.8.23.xpi";
          installation_mode = "force_installed";
        };

        "{e7476172-097c-4b77-b56e-f56a894adca9}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4472493/minimaltwitter-6.3.0.xpi";
          installation_mode = "force_installed";
        };

        "vimium-c@gdh1995.cn" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4474326/vimium_c-2.12.3.xpi";
          installation_mode = "force_installed";
        };

        "{eac6e624-97fa-4f28-9d24-c06c9b8aa713}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4519503/material_icons_for_github-1.10.5.xpi";
          installation_mode = "force_installed";
        };
      };

      # Enhanced Preferences - Productivity & UX focused
      Preferences = {
        # 🏠 Homepage & Startup
        "browser.startup.homepage" = "http://localhost:8080/development";
        "browser.newtabpage.enabled" = false;
        "browser.startup.page" = 1; # 0=blank, 1=home, 2=last visited page, 3=resume previous session
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

        # 📑 Tab Management
        "browser.tabs.warnOnClose" = false;
        "browser.tabs.warnOnOpen" = false;
        "browser.tabs.closeWindowWithLastTab" = false;
        "browser.tabs.insertAfterCurrent" = true;
        "browser.tabs.insertRelatedAfterCurrent" = true;

        # 🎨 Zen Browser UI - Optimized for productivity
        "zen.view.compact" = true;
        "zen.view.sidebar-expanded" = false;
        "zen.tabs.hide-tabbar" = true;
        "zen.workspaces.enabled" = true;
        "zen.sidebar.enabled" = true;
        "zen.sidebar.position" = "left";
        "zen.view.use-single-toolbar" = true;
        "zen.view.show-newtab-button" = false;
        "zen.view.hide-window-controls" = false;
        "zen.view.experimental-vertical-tabs" = false;

        # ⚡ Performance & Hardware
        "media.hardware-video-decoding.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "dom.webgpu.enabled" = true;
        "gfx.webrender.all" = true;
        "layers.acceleration.force-enabled" = true;

        # 🖱️ Scrolling & Interaction
        "general.smoothScroll" = true;
        "general.smoothScroll.mouseWheel.durationMaxMS" = 400;
        "general.smoothScroll.mouseWheel.durationMinMS" = 200;
        "apz.gtk.kinetic_scroll.enabled" = true;

        # 🔒 Privacy & Security
        "media.peerconnection.enabled" = false;
        "privacy.resistFingerprinting" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.userContext.enabled" = true;
        "dom.security.https_only_mode" = true;

        # 💾 Downloads & Files
        "browser.download.useDownloadDir" = true;
        "browser.download.alwaysOpenPanel" = false;
        "browser.download.manager.addToRecentDocs" = false;

        # 🔍 Search & Find
        "findbar.highlightAll" = true;
        "findbar.modalHighlight" = true;
        "accessibility.typeaheadfind" = true;

        # 📝 Developer Tools
        "devtools.theme" = "dark";
        "devtools.toolbox.host" = "bottom";
        "devtools.debugger.ui.editor-wrapping" = true;
        "devtools.editor.keymap" = "vim";

        # 🌐 Network & Performance
        "network.http.max-connections" = 256;
        "network.http.max-persistent-connections-per-server" = 10;
        "network.dns.disablePrefetch" = false;
        "network.predictor.enabled" = true;

        # 🎵 Media & Audio
        "media.autoplay.default" = 1; # 0=allow, 1=block, 2=prompt
        "media.autoplay.blocking_policy" = 2;
        "media.block-autoplay-until-in-foreground" = true;

        # 📱 Touch & Gestures
        "apz.gtk.pinch_to_zoom.enabled" = true;
        "apz.gtk.touchpad_pinch.enabled" = true;
        "browser.gesture.pinch.in" = "cmd_fullZoomReduce";
        "browser.gesture.pinch.out" = "cmd_fullZoomEnlarge";

        # ⌨️ Keyboard Shortcuts
        "ui.key.accelKey" = 17; # Ctrl key
        "ui.key.menuAccessKey" = 18; # Alt key

        # 🖼️ Images & Content
        "permissions.default.image" = 1; # Block images by default for privacy
        "browser.display.use_document_fonts" = 1;
        "layout.css.devPixelsPerPx" = "1.0";

        "toolkit.telemetry.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "browser.crashReports.unsubmittedCheck.enabled" = false;
      };
    };

    # Profile configuration with containers and spaces
    profiles."default" = {
      # Force containers and spaces to be declarative
      containersForce = true;
      spacesForce = true;

      # Container configuration
      containers = {
        Personal = {
          color = "purple";
          icon = "fingerprint";
          id = 1;
        };

        Work = {
          color = "blue";
          icon = "briefcase";
          id = 2;
        };

        Shopping = {
          color = "yellow";
          icon = "cart";
          id = 3;
        };

        Social = {
          color = "red";
          icon = "circle";
          id = 4;
        };
      };

      # Spaces configuration
      spaces = {
        "Personal" = {
          id = "c6de089c-410d-4206-961d-ab11f988d40a";
          position = 1000;
          icon = "🏠";
          container = 1;
        };

        "Work" = {
          id = "cdd10fab-4fc5-494b-9041-325e5759195b";
          position = 2000;
          icon = "💼";
          container = 2;
        };

        "Shopping" = {
          id = "78aabdad-8aae-4fe0-8ff0-2a0c6c4ccc24";
          position = 3000;
          icon = "🛒";
          container = 3;
        };

        "Social" = {
          id = "a1b2c3d4-e5f6-7890-abcd-ef1234567890";
          position = 4000;
          icon = "👥";
          container = 4;
        };
      };
    };
  };
}
