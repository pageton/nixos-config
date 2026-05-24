# LibreWolf browser with declarative baseline policies, multi-profile proxy setup, and extensions.
# Each profile is fully isolated with its own proxy — never mix proxies.
{
  pkgsStable,
  lib,
  config,
  constants,
  ...
}:
let
  extensionPolicies = import ./_extensions.nix;
  profileSpecs = import ./_profiles.nix { inherit constants; };
  baseSettings = {
    "app.update.auto" = false;
    "browser.shell.checkDefaultBrowser" = false;
    "browser.startup.page" = 3;
    "browser.newtabpage.enabled" = true;
    "browser.urlbar.focusOnNewTab" = false;
    "browser.privatebrowsing.autostart" = false;
    "browser.compactmode.show" = true;
    "browser.uidensity" = 1;
    "browser.toolbars.bookmarks.visibility" = "newtab";
    "browser.tabs.loadInBackground" = true;
    "browser.tabs.warnOnClose" = false;
    "browser.tabs.closeWindowWithLastTab" = false;

    # Theme — Gruvbox Material Dark
    "extensions.activeThemeID" = "{1e01c787-99d2-4826-86df-0003da8e88cd}";
    "layout.css.prefers-color-scheme.content-override" = 0;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "layout.css.moz-document.content.enabled" = true;

    # Sidebar - vertical tabs
    "sidebar.revamp" = true;
    "sidebar.verticalTabs" = true;
    "sidebar.visibility" = "always-show";

    # Privacy
    "media.peerconnection.enabled" = false;
    "network.cookie.lifetimePolicy" = 0;
    "privacy.clearOnShutdown.cookies" = false;
    "privacy.clearOnShutdown.offlineApps" = false;
    "privacy.clearOnShutdown.history" = false;
    "privacy.clearOnShutdown.cache" = false;
    "privacy.sanitize.sanitizeOnShutdown" = false;

    # Anti-fingerprinting
    "privacy.resistFingerprinting" = true;
    "privacy.fingerprintingProtection" = true;
    "privacy.fingerprintingProtection.overrides" = "";
    "privacy.trackingprotection.enabled" = true;
    "privacy.trackingprotection.socialtracking.enabled" = true;
    "privacy.trackingprotection.cryptomining.enabled" = true;
    "privacy.trackingprotection.fingerprinting.enabled" = true;
    "privacy.firstparty.isolate" = true;
    "privacy.query_stripping.enabled" = true;
    "privacy.query_stripping.strip_list" =
      "utm_source utm_medium utm_campaign utm_term utm_content fbclid gclid dclid twclid";
    "webgl.disabled" = true;
    "geo.enabled" = false;
    "media.navigator.enabled" = false;

    # Memory optimization
    "dom.ipc.processCount" = 2;
    "browser.tabs.unloadOnLowMemory" = true;
    "browser.sessionstore.interval" = 30000;
    "media.memory_cache_max_size" = 524288;
    "browser.cache.memory.capacity" = 262144;
    "browser.cache.memory.max_entry_size" = 5120;
    "image.mem.animated.unrolling.minms" = 5000;
    "image.mem.decode_bytes_at_a_time" = 65536;
    "browser.sessionstore.max_tabs_undo" = 5;
    "browser.sessionstore.max_resumed_crashes" = 1;

    # Proxy base config (host set per-profile)
    "network.proxy.type" = 1;
    "network.proxy.socks_port" = constants.ports.socks;
    "network.proxy.socks_version" = 5;
    "network.proxy.socks_remote_dns" = true;

    # New Tab Override
    "browser.newtab.extension.active" = true;
    "newtaboverride.url.url" =
      "http://${constants.localhost}:${toString constants.ports.glance}/search";
    "network.protocol-handler.external.ytmpv" = true;
    "network.protocol-handler.expose.ytmpv" = false;
    "network.protocol-handler.warn-external.ytmpv" = false;
  };

  # Generate launcher script for a profile.
  mkLauncher = name: profilePath: {
    ".local/bin/librewolf-${name}" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        PROFILE_DIR="$HOME/.librewolf/${profilePath}"
        rm -f "$PROFILE_DIR/.parentlock" "$PROFILE_DIR/lock"

        if [ "$#" -gt 0 ]; then
          exec ${pkgsStable.librewolf}/bin/librewolf \
            --name librewolf-${name} \
            --profile "$PROFILE_DIR" \
            --new-tab "$1"
        fi

        exec ${pkgsStable.librewolf}/bin/librewolf \
          --new-instance \
          --name librewolf-${name} \
          --profile "$PROFILE_DIR"
      '';
    };
  };

  # Generate chrome file symlinks for a profile.
  mkChromeFiles = profilePath: {
    ".librewolf/${profilePath}/chrome/userChrome.css".source = ../../themes/librewolf-userChrome.css;
    ".librewolf/${profilePath}/chrome/userContent.css".source = ../../themes/librewolf-userContent.css;
  };

  mkProfile = spec: {
    inherit (spec) id isDefault path;
    settings =
      baseSettings
      // {
        "browser.startup.homepage" = spec.homepage;
        "network.proxy.socks" = spec.proxyHost;
      }
      // (spec.extraSettings or { });
  };

  librewolfProfileFiles = builtins.listToAttrs (
    lib.flatten (
      map (
        spec:
        (lib.mapAttrsToList (name: value: { inherit name value; }) (mkLauncher spec.name spec.path))
        ++ (lib.mapAttrsToList (name: value: { inherit name value; }) (mkChromeFiles spec.path))
      ) profileSpecs
    )
  );

  generatedProfiles = builtins.listToAttrs (
    map (spec: {
      inherit (spec) name;
      value = mkProfile spec;
    }) profileSpecs
  );
in
{
  home.file = librewolfProfileFiles // {
    ".librewolf/profiles.ini".force = true;
  };

  programs.librewolf = {
    enable = true;
    package = pkgsStable.librewolf;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      inherit (extensionPolicies) ExtensionSettings;
      "3rdparty" = {
        Extensions = {
          "newtaboverride@agenedia.com" = {
            type = "homepage";
          };
        };
      };
      UserMessaging = {
        ExtensionRecommendations = false;
        SkipOnboarding = true;
      };
    };

    profiles = generatedProfiles;
  };

  xdg.desktopEntries = builtins.listToAttrs (
    map (spec: {
      name = "librewolf-${spec.name}";
      value = {
        name = "LibreWolf ${spec.label}";
        exec = "${config.home.homeDirectory}/.local/bin/librewolf-${spec.name} %U";
        icon = "librewolf";
        inherit (spec) comment;
        categories = [ "Network" ];
        mimeType = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
      };
    }) profileSpecs
  );
}
