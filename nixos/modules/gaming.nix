# Gaming-related configurations (Steam, MangoHud, etc.).
{
  config,
  lib,
  pkgs,
  ...
}:
{
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

      gamescope = lib.mkIf config.mySystem.gaming.enableGamescope {
        enable = true;
        capSysNice = true;
      };
    };

    # Environment variables for Steam and compatibility tools
    environment = {
      sessionVariables = {
        # Standard Steam path for third-party compatibility tools (Proton-GE, etc.)
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
        # MangoHud default overlay config
        MANGOHUD_CONFIG = "fps,frametime,gpu_stats,gpu_temp,cpu_stats,cpu_temp,ram,vram";
      };

      systemPackages = with pkgs; [
        mangohud # Vulkan/OpenGL overlay for FPS, frame timing, GPU stats
        protonup-ng # Proton-GE version manager
        lutris # Multi-platform game launcher
        steam-run # FHS environment for running non-Nix Linux games
        wine # Windows compatibility layer
        winetricks # Wine configuration helper
        libunwind # Stack unwinding library required by some Proton games
      ];
    };
  };
}
