# Gaming-related configurations (Steam, MangoHud, etc.).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.mySystem.gaming = {
    enable = lib.mkEnableOption "gaming support with Steam and related tools";

    enableGamescope = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable gamescope session for Steam";
    };
  };

  config = lib.mkIf config.mySystem.gaming.enable {
    programs = {
      steam = {
        enable = true;
        gamescopeSession.enable = config.mySystem.gaming.enableGamescope;
      };
    };

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };

    environment.systemPackages = with pkgs; [
      mangohud # Vulkan overlay
      protonup # Proton compatibility tool
      (bottles.override { removeWarningPopup = true; })
    ];
  };
}
