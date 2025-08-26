# Zen Browser configuration.

{
  inputs,
  ...
}:

{
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser = {
    enable = true;

    # Policies for enhanced privacy and security
    policies = {
      # Disable telemetry and data collection
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFeedbackCommands = true;

      # Privacy settings
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      # Disable automatic updates and checks
      DisableAppUpdate = true;
      DontCheckDefaultBrowser = true;

      # Login and autofill settings
      OfferToSaveLogins = false;
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;

      # Remove default bookmarks
      NoDefaultBookmarks = true;

      # Extension settings - Only verified working extensions
      ExtensionSettings = {
        # Working extensions (confirmed installed)
        "addon@darkreader.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          installation_mode = "force_installed";
        };

        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };

        "{c3c10168-4186-445c-9c5b-63f12b8e2c87}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/cookie-editor/latest.xpi";
          installation_mode = "force_installed";
        };

        "{6AC85730-7D0F-4de0-B3FA-21142DD85326}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/colorzilla/latest.xpi";
          installation_mode = "force_installed";
        };

        "amptra@keepa.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepa/latest.xpi";
          installation_mode = "force_installed";
        };

        "{74145f27-f039-47ce-a470-a662b129930a}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi";
          installation_mode = "force_installed";
        };

        "adguardadblocker@adguard.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/adguard-adblocker/latest.xpi";
          installation_mode = "force_installed";
        };

        "wappalyzer@crunchlabz.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/wappalyzer/latest.xpi";
          installation_mode = "force_installed";
        };

        # Additional extensions from your current setup
        "{a6c4a591-f1b2-4f03-b3ff-767e5bedf4e7}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4497925/user_agent_string_switcher-0.6.5.1.xpi";
          installation_mode = "force_installed";
        };

        "jid1-ZAdIEUB7XOzOJw@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4540706/duckduckgo_for_firefox-2025.7.23.xpi";
          installation_mode = "force_installed";
        };

        "{c45c406e-ab73-11d8-be73-000a95be3b12}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4306323/web_developer-3.0.1.xpi";
          installation_mode = "force_installed";
        };

        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4541835/sponsorblock-5.14.xpi";
          installation_mode = "force_installed";
        };

        "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4371820/return_youtube_dislikes-3.0.0.18.xpi";
          installation_mode = "force_installed";
        };

        "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4563040/refined_github-25.8.23.xpi";
          installation_mode = "force_installed";
        };

        "@react-devtools" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4432990/react_devtools-6.1.1.xpi";
          installation_mode = "force_installed";
        };

        "{e7476172-097c-4b77-b56e-f56a894adca9}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4472493/minimaltwitter-6.3.0.xpi";
          installation_mode = "force_installed";
        };

        "{16a49f65-1369-4839-a5ef-db2581e08b16}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/3736573/json_lite-21.3.0.xpi";
          installation_mode = "force_installed";
        };

        "{3c6bf0cc-3ae2-42fb-9993-0d33104fdcaf}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4544885/youtube_addon-4.1323.xpi";
          installation_mode = "force_installed";
        };
      };

      # Preferences
      Preferences = {
        # Disable tab warnings
        "browser.tabs.warnOnClose" = false;
        "browser.tabs.warnOnOpen" = false;

        # Enable hardware acceleration
        "media.hardware-video-decoding.enabled" = true;

        # Better scrolling
        "general.smoothScroll" = true;

        # Disable webRTC leak protection (optional)
        "media.peerconnection.enabled" = false;
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
