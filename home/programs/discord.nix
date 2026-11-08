# Discord (Vesktop + Vencord) declarative configuration via nixcord.
{
  inputs,
  lib,
  pkgs,
  config,
  ...
}:

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
      # NVIDIA proprietary driver: Chromium refuses Vulkan GPU init under
      # ozone/wayland ("--ozone-platform=wayland is not compatible with
      # Vulkan") and the window comes up blank. Disabling Vulkan makes it
      # fall back to GL while keeping native Wayland output and IME.
      commandLineArgs = [ "--disable-vulkan" ];
    };
    vesktop = {
      enable = true;
      # NVIDIA proprietary driver: Chromium refuses Vulkan GPU init under
      # ozone/wayland and the window comes up blank; disable Vulkan so GL
      # takes over. nixcord exposes no commandLineArgs for Vesktop and
      # re-overrides the package itself (.override { withSystemVencord }),
      # so patch via overrideAttrs, which composes with that.
      package = pkgs.vesktop.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
        postFixup = (old.postFixup or "") + ''
          wrapProgram "$out/bin/vesktop" --add-flags "--disable-vulkan"
        '';
      });
    };

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

  # nixcord pins Vesktop's Vencord settings.json to a read-only store
  # symlink, but Vencord rewrites it on every renderer settings change —
  # every write fails with EROFS and in-app plugin edits are lost. Each
  # switch HM recreates the symlink; convert it to a real writable copy
  # afterwards (same shape as nixcord's own writable settings handling).
  home.activation.vesktopWritableSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    f="${config.xdg.configHome}/vesktop/settings/settings.json"
    if [ -L "$f" ]; then
      src="$(readlink -f "$f")"
      run rm "$f"
      run ${lib.meta.getExe' pkgs.coreutils "install"} -Dm644 "$src" "$f"
    fi
  '';
}
