{ pkgs, config, ... }:

let
  # Using beta driver for recent GPUs like RTX 4070
  nvidiaDriverChannel = config.boot.kernelPackages.nvidiaPackages.beta;
in
{
  # Video drivers configuration for Xorg and Wayland
  services.xserver.videoDrivers = [ "nvidia" ]; # Simplified - other modules are loaded automatically

  # Kernel parameters for better Wayland and Hyprland integration
  boot.kernelParams = [
    "nvidia-drm.modeset=1" # Enable mode setting for Wayland
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Improves resume after sleep
  ];

  # Blacklist nouveau to avoid conflicts
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Environment variables for better compatibility
  environment.variables = {
    LIBVA_DRIVER_NAME = "nvidia"; # Hardware video acceleration
    XDG_SESSION_TYPE = "wayland"; # Force Wayland
    GBM_BACKEND = "nvidia-drm"; # Graphics backend for Wayland
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # Use Nvidia driver for GLX
    WLR_NO_HARDWARE_CURSORS = "1"; # Fix for cursors on Wayland
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    __GL_GSYNC_ALLOWED = "1"; # Enable G-Sync if available
    __GL_VRR_ALLOWED = "1"; # Enable VRR (Variable Refresh Rate)
    WLR_DRM_NO_ATOMIC = "1"; # Fix for some issues with Hyprland
    NVD_BACKEND = "direct"; # Configuration for new driver
    MOZ_ENABLE_WAYLAND = "1"; # Wayland support for Firefox
  };

  # Configuration for proprietary packages
  nixpkgs.config = {
    nvidia.acceptLicense = true;
    allowUnfree = true;
  };

  # Nvidia configuration
  hardware = {
    nvidia = {
      open = false;
      nvidiaSettings = true; # Nvidia settings utility
      modesetting.enable = true; # Required for Wayland
      package = nvidiaDriverChannel;

      powerManagement = {
        enable = true; # Power management
      };
    };

    # Enhanced graphics support
    graphics = {
      enable = true;
      package = nvidiaDriverChannel;
      enable32Bit = true;

      extraPackages = with pkgs; [
        nvidia-vaapi-driver # VA-API support
        vaapiVdpau # VDPAU for VA-API
        libvdpau-va-gl # VDPAU for VA-API
        mesa # Vulkan driver
        egl-wayland # EGL for Wayland
        vulkan-loader # Vulkan loader
        vulkan-validation-layers # Vulkan validation layers
        libva # Video Acceleration
      ];
    };
  };

  # Nix cache for CUDA
  nix.settings = {
    substituters = [ "https://cuda-maintainers.cachix.org" ];

    trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };

  # Additional useful packages
  environment.systemPackages = with pkgs; [
    vulkan-tools # Vulkan debugging tools
    glxinfo # GLX information
    libva-utils # VA-API debugging tools
  ];
}
