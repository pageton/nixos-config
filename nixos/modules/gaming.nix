# Gaming: Steam, Proton-GE, Proton-CachyOS, SLSsteam, MangoHud, Lutris, gamescope (desktop host only).
{ lib, pkgs, ... }:

let
  # Steam client modification for Enter The Wired (yzua port); injected via
  # upstream's documented NixOS LD_AUDIT integration, not a client downgrade.
  slssteam = pkgs.callPackage ../../packages/slssteam { };
in
{
  programs = {
    steam = {
      enable = true;
      package = pkgs.steam.override {
        extraEnv.LD_AUDIT = "${slssteam}/library-inject.so:${slssteam}/SLSsteam.so";
      };
      # MangoHud available inside the Steam runtime for `mangohud %command%`.
      extraPackages = [ pkgs.mangohud ];
      gamescopeSession.enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin # Proton-GE for better game compatibility
        (pkgs.callPackage ../../packages/proton-cachyos-bin { }) # Proton-CachyOS (Steam Linux Runtime)
      ];
    };

    gamescope = {
      enable = true;
      capSysNice = true;
    };

    # Game mode — auto-switches CPU governor to performance during gaming
    gamemode.enable = true;
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
}
