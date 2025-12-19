# Gaming-related configurations (Steam, MangoHud, etc.).
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Custom module options for gaming configuration
  options.mySystem.gaming = {
    enable = lib.mkEnableOption "gaming support with Steam and related tools";

    enableGamescope = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable gamescope session for Steam";
    };
  };

  # Configuration applied when gaming is enabled
  config = lib.mkIf config.mySystem.gaming.enable {
    programs = {
      steam = {
        enable = true; # Enable Steam gaming platform
        gamescopeSession.enable = config.mySystem.gaming.enableGamescope; # Enable GameScope session
        extraCompatPackages = with pkgs; [
          proton-ge-bin # Proton-GE for better game compatibility
        ];
      };
    };

    # Environment variables for Steam and compatibility tools
    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d"; # Proton compatibility tools path
    };

    # Gaming-related system packages
    environment.systemPackages = with pkgs; [
      mangohud # Vulkan overlay for performance monitoring
      protonup-ng # Tool for managing Proton compatibility layers
      lutris # Open gaming platform for managing multiple game sources
      wine # Compatibility layer for running Windows programs
      winetricks # Helper for configuring Wine
    ];
  };
}
