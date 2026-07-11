# Discord (Vesktop + Vencord) declarative configuration via nixcord.
{ inputs, ... }:

let
  mkEnabledPlugins =
    names:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value.enable = true;
      }) names
    );

  uiUxPlugins = [
    "alwaysTrust"
    "betterFolders"
    "betterRoleContext"
    "crashHandler"
    "fakeNitro"
    "fixSpotifyEmbeds"
    "imageZoom"
    "memberCount"
    "permissionsViewer"
    "pinDms"
    "quickMention"
    "readAllNotificationsButton"
    "revealAllSpoilers"
    "serverListIndicators"
    "spotifyControls"
    "themeAttributes"
    "typingIndicator"
    "voiceMessages"
    "volumeBooster"
    "webContextMenus"
    "whoReacted"
  ];

  privacyPlugins = [
    "anonymiseFileNames"
    "clearUrls"
    "silentTyping"
  ];

  loggingNotificationPlugins = [
    "messageLogger"
    "relationshipNotifier"
  ];
in
{
  imports = [ inputs.nixcord.homeModules.nixcord ];

  programs.nixcord = {
    enable = true;

    discord = {
      enable = true;
      # Patch vanilla Discord with Vencord so the configured plugins below
      # actually apply. Without this, nixcord warns that Discord ships with
      # no client mod (vencord/equicord both disabled).
      vencord.enable = true;
    };
    vesktop.enable = true;

    config = {
      useQuickCss = true;
      frameless = true;

      # Catppuccin Mocha theme (catppuccin/discord — maintained for latest Discord UI)
      themeLinks = [ "https://raw.githubusercontent.com/catppuccin/discord/main/themes/mocha.theme.css" ];

      plugins =
        mkEnabledPlugins uiUxPlugins
        // mkEnabledPlugins privacyPlugins
        // mkEnabledPlugins loggingNotificationPlugins;
    };
  };
}
