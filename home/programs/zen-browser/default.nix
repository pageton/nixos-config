# Zen Browser with declarative baseline policies, multi-profile proxy setup, and extensions.
# Each profile is fully isolated with its own proxy — never mix proxies.
{
  pkgs,
  lib,
  config,
  constants,
  ...
}:
let
  extensionPolicies = import ./_extensions.nix;
  profileSpecs = import ./_profiles.nix { inherit constants; };
  zenBin = "${config.programs.zen-browser.package}/bin/zen-beta";

  baseSettings = {
    "app.update.auto" = false;
    "browser.shell.checkDefaultBrowser" = false;
    "browser.startup.page" = 3;
    "browser.newtabpage.enabled" = true;
    "browser.privatebrowsing.autostart" = false;
    "browser.compactmode.show" = true;
    "browser.uidensity" = 1;
    "browser.toolbars.bookmarks.visibility" = "newtab";
    "browser.tabs.loadInBackground" = true;
    "browser.tabs.warnOnClose" = false;
    "browser.tabs.closeWindowWithLastTab" = false;

    # Theme — Catppuccin Mocha Mauve (AMO: catppuccin-mocha-mauve-git)
    "extensions.activeThemeID" = "{76aabc99-c1a8-4c1e-832b-d4f2941d5a7a}";
    "layout.css.prefers-color-scheme.content-override" = 2;
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "layout.css.moz-document.content.enabled" = true;

    # Sidebar - disabled for Sidebery
    "sidebar.revamp" = false;
    "sidebar.verticalTabs" = false;
    "sidebar.visibility" = "hide-sidebar";

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

    # Proxy base config (host set per-profile)
    "network.proxy.type" = 1;
    "network.proxy.socks_port" = constants.ports.socks;
    "network.proxy.socks_version" = 5;
    "network.proxy.socks_remote_dns" = true;

    # ytmpv protocol handler
    "network.protocol-handler.external.ytmpv" = true;
    "network.protocol-handler.expose.ytmpv" = false;
    "network.protocol-handler.warn-external.ytmpv" = false;
  };

  mkLauncher = name: profilePath: {
    ".local/bin/zen-${name}" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        if [ "$#" -gt 0 ]; then
          exec ${zenBin} \
            --name zen-${name} \
            --profile "$HOME/.config/zen/${profilePath}" \
            --new-tab "$1"
        fi

        exec ${zenBin} \
          --new-instance \
          --name zen-${name} \
          --profile "$HOME/.config/zen/${profilePath}"
      '';
    };
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

  zenProfileFiles = builtins.listToAttrs (
    lib.flatten (
      map (
        spec: lib.mapAttrsToList (name: value: { inherit name value; }) (mkLauncher spec.name spec.path)
      ) profileSpecs
    )
  );

  zenBrowserWrapper = {
    ".local/bin/zen-browser" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail

        firejail_bin="/run/wrappers/bin/firejail"
        firejail_profile="/etc/firejail/zen-browser.profile"
        mesa_egl_vendor="/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json"

        if [ -x "$firejail_bin" ] && [ -f "$firejail_profile" ]; then
          exec "$firejail_bin" \
            --profile="$firejail_profile" \
            --env=__EGL_VENDOR_LIBRARY_FILENAMES="$mesa_egl_vendor" \
            -- ${zenBin} "$@"
        fi

        exec ${zenBin} "$@"
      '';
    };
  };

  generatedProfiles = builtins.listToAttrs (
    map (spec: {
      inherit (spec) name;
      value = mkProfile spec;
    }) profileSpecs
  );
in
{
  home.file = zenProfileFiles // zenBrowserWrapper;

  programs.zen-browser = {
    enable = true;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      SearchEngines = {
        Default = "DuckDuckGo";
      };
      DontCheckDefaultBrowser = true;
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;
      inherit (extensionPolicies) ExtensionSettings;
      UserMessaging = {
        ExtensionRecommendations = false;
        SkipOnboarding = true;
      };
    };

    profiles = generatedProfiles;
  };

  xdg.desktopEntries = builtins.listToAttrs (
    map (spec: {
      name = "zen-${spec.name}";
      value = {
        name = "Zen ${spec.label}";
        exec = "${config.home.homeDirectory}/.local/bin/zen-${spec.name} %U";
        icon = "zen-browser";
        comment = spec.comment;
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
