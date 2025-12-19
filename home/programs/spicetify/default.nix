# Spicetify (Spotify client customizer) configuration.
{
  pkgs,
  inputs,
  ...
}: let
  # Spicetify package set from the flake input
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  # Import the Spicetify home-manager module
  imports = [inputs.spicetify-nix.homeManagerModules.default];

  # Disable Stylix integration for manual theme control
  stylix.targets.spicetify.enable = false;

  # Spicetify configuration
  programs.spicetify = {
    enable = true; # Enable Spicetify customization

    # Enabled Spicetify extensions for enhanced functionality
    enabledExtensions = with spicePkgs.extensions; [
      playlistIcons # Add icons to playlists
      lastfm # Last.fm integration
      historyShortcut # Keyboard shortcuts for history
      hidePodcasts # Hide podcasts from interface
      adblock # Block ads in Spotify
      fullAppDisplay # Full app display mode
      keyboardShortcut # Additional keyboard shortcuts
    ];
  };

  # Environment variables to improve Spotify stability and performance
  home.sessionVariables = {
    # Increase memory cache size for better performance
    SPOTIFY_MAX_CACHE_SIZE_MB = "1024";

    # Additional stability flags
    SPOTIFY_SKIP_LINUX_NOTIFICATIONS = "1"; # Skip problematic notifications
  };
}
