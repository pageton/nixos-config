# Brave browser with declarative extensions, multi-profile proxy setup, and launchers.
# Each profile is fully isolated with its own proxy — never mix proxies.
{
  pkgs,
  lib,
  config,
  constants,
  ...
}:
let
  extensionSpecs = import ./_extensions.nix;
  profileSpecs = import ./_profiles.nix { inherit constants; };

  braveBin = "${pkgs.brave}/bin/brave";

  mkLauncher =
    spec:
    let
      homepageArg = if spec.homepage != "about:blank" then "--new-tab ${spec.homepage}" else "";
    in
    {
      ".local/bin/brave-${spec.name}" = {
        executable = true;
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail

          if [ "$#" -gt 0 ]; then
            exec ${braveBin} \
              --name brave-${spec.name} \
              --profile-directory="${spec.path}" \
              --proxy-server="socks5://${spec.proxyHost}:${toString constants.ports.socks}" \
              --new-tab "$1"
          fi

          exec ${braveBin} \
            --new-instance \
            --name brave-${spec.name} \
            --profile-directory="${spec.path}" \
            --proxy-server="socks5://${spec.proxyHost}:${toString constants.ports.socks}" \
            ${homepageArg}
        '';
      };
    };

  mkPolicy = {
    "BraveSoftware/Brave-Browser/managed/managed_policies.json".text = builtins.toJSON {
      IncognitoModeAvailability = 0;
      AllowDeletingBrowsingHistory = true;
      BrowserSignin = 0;
      SyncDisabled = true;
      PasswordManagerEnabled = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      BackgroundModeEnabled = false;
      BraveRewardsDisabled = true;
      BraveWalletDisabled = true;
      BraveVPNDisabled = true;
      BraveAIChatEnabled = false;
      TorDisabled = true;
      BraveGoogleSignInDisabled = true;
      BraveWebtorrentDisabled = true;
      BraveDeAMPDisabled = true;
      HttpsOnlyMode = "forced";
      SafeBrowsingProtectionLevel = 2;
      BlockThirdPartyCookies = true;
      ImportAutofillFormData = false;
      ImportBookmarks = false;
      ImportHistory = false;
      ImportHomepage = false;
      ImportSavedPasswords = false;
      ImportSearchEngines = false;
    };
  };

  braveProfileFiles = builtins.listToAttrs (
    lib.flatten (
      map (spec: lib.mapAttrsToList (name: value: { inherit name value; }) (mkLauncher spec)) profileSpecs
    )
  );
in
{
  home.file =
    braveProfileFiles
    // mkPolicy
    // {
      "${config.xdg.configHome}/BraveSoftware/Brave-Browser/managed/managed_policies.json".text =
        builtins.toJSON
          { };
    };

  programs.brave = {
    enable = true;
    package = pkgs.brave;
    extensions = extensionSpecs.extensions;
    commandLineArgs = [
      "--enable-features=WaylandWindowDecorations"
      "--ozone-platform-hint=auto"
      "--disable-features=BraveRewards"
    ];
  };

  xdg.desktopEntries = builtins.listToAttrs (
    map (spec: {
      name = "brave-${spec.name}";
      value = {
        name = "Brave ${spec.label}";
        exec = "${config.home.homeDirectory}/.local/bin/brave-${spec.name} %U";
        icon = "brave-browser";
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
