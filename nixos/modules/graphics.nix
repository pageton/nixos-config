# Graphics and NVIDIA driver configuration.
# This module configures NVIDIA graphics drivers with optimized settings
# for gaming, Wayland compositors, and hardware acceleration.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Using stable driver to match kernel module version
  nvidiaDriverChannel = config.boot.kernelPackages.nvidiaPackages.stable;
in {
  config = {
    # Video drivers configuration for Xorg and Wayland
    services.xserver.videoDrivers = ["nvidia"]; # Use NVIDIA proprietary driver

    # Kernel parameters for Wayland compositor integration
    boot.kernelParams = [
      "nvidia-drm.modeset=1" # Enable DRM kernel mode setting for Wayland
      "nvidia-drm.fbdev=1" # Use NVIDIA framebuffer device — fixes rendering glitches
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Preserve GPU memory on suspend/resume
    ];

    # Blacklist nouveau to avoid conflicts with proprietary driver
    boot.blacklistedKernelModules = ["nouveau"];

    # Environment variables for better compatibility and performance
    # Note: WLR_* vars belong in Hyprland config (wlroots-specific, not needed by Niri).
    # GBM_BACKEND removed — modern NVIDIA drivers (580+) handle GBM natively.
    # __GL_GSYNC_ALLOWED/__GL_VRR_ALLOWED removed — let the compositor manage VRR.
    environment.variables = {
      LIBVA_DRIVER_NAME = "nvidia"; # Use NVIDIA for hardware video acceleration
      XDG_SESSION_TYPE = "wayland"; # Force Wayland session
      __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # Force NVIDIA GLX driver
      ELECTRON_OZONE_PLATFORM_HINT = "auto"; # Auto-detect Electron platform
      NVD_BACKEND = "direct"; # Direct backend for new NVIDIA driver
      MOZ_ENABLE_WAYLAND = "1"; # Enable Wayland support in Firefox
    };

    # Configuration for proprietary packages
    nixpkgs.config = {
      nvidia.acceptLicense = true;
      allowUnfree = true;
    };

    # Hardware configuration for NVIDIA graphics
    hardware = {
      nvidia = {
        open = false; # Use proprietary driver (not open source)
        nvidiaSettings = true; # Enable nvidia-settings utility
        modesetting.enable = true; # Required for Wayland compositors
        package = nvidiaDriverChannel; # Use beta driver package

        powerManagement = {
          enable = true; # Enable power management for better battery life
          finegrained = false; # Disable fine-grained power management
        };
      };

      # Enhanced graphics support with hardware acceleration
      graphics = {
        enable = true; # Enable graphics support
        package = nvidiaDriverChannel; # Use same driver for consistency
        enable32Bit = true; # Enable 32-bit support for legacy applications

        # Additional graphics packages for full hardware acceleration
        extraPackages = with pkgs; [
          nvidia-vaapi-driver # NVIDIA VA-API driver for video acceleration
          libva-vdpau-driver # VDPAU backend for VA-API
          libvdpau-va-gl # OpenGL backend for VDPAU
          mesa # Mesa Vulkan drivers
          egl-wayland # EGL platform for Wayland
          vulkan-loader # Vulkan API loader
          vulkan-validation-layers # Vulkan validation and debugging
          libva # Video Acceleration API
        ];
      };
    };

    # Nix binary cache for CUDA packages
    nix.settings = {
      substituters = ["https://cuda-maintainers.cachix.org"]; # CUDA package cache

      trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };

    # Additional graphics debugging and utility packages
    environment.systemPackages = with pkgs; [
      vulkan-tools # Vulkan debugging and information tools
      mesa-demos # OpenGL and GLX information utility
      libva-utils # VA-API debugging and testing utilities
      cudaPackages.cudatoolkit # CUDA development tools
    ];

    # NVIDIA application profile for Niri — fixes VRAM leak causing progressive
    # rendering degradation. See: https://github.com/YaLTeR/niri/wiki/Nvidia
    environment.etc."nvidia/nvidia-application-profiles-rc.d/50-niri-vram-fix.json".text = builtins.toJSON {
      rules = [
        {
          pattern = {
            feature = "procname";
            matches = "niri";
          };
          profile = "Limit Free Buffer Pool On Wayland Compositors";
        }
      ];
      profiles = [
        {
          name = "Limit Free Buffer Pool On Wayland Compositors";
          settings = [
            {
              key = "GLVidHeapReuseRatio";
              value = 0;
            }
          ];
        }
      ];
    };

    # Udev rules for NVIDIA device access
    services.udev.extraRules = ''
      # NVIDIA GPU access for users in video group
      KERNEL=="nvidia*", GROUP="video", MODE="0660"
      KERNEL=="nvidiactl", GROUP="video", MODE="0660"
      KERNEL=="nvidia-modeset", GROUP="video", MODE="0660"
    '';
  };
}