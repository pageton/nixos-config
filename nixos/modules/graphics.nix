# Graphics and NVIDIA driver configuration.
{
  config,
  pkgs,
  lib,
  ...
}: let
  nvidiaDriverChannel = config.boot.kernelPackages.nvidiaPackages.stable;
in {
  config = {
    # Use proprietary NVIDIA userspace + kernel stack.
    services.xserver.videoDrivers = ["nvidia"];

    boot = {
      kernelParams = [
        # Required for stable Wayland compositors on NVIDIA.
        "nvidia-drm.modeset=1"
        # Preserve VRAM across suspend/resume transitions.
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      ];
      # Prevent nouveau from racing/loading before proprietary modules.
      blacklistedKernelModules = ["nouveau"];
    };

    # Session/runtime compatibility for Wayland + VA-API + GLX selection.
    environment.variables = {
      LIBVA_DRIVER_NAME = "nvidia";
      XDG_SESSION_TYPE = "wayland";
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      NVD_BACKEND = "direct";
      MOZ_ENABLE_WAYLAND = "1";
    };

    nixpkgs.config = {
      # NVIDIA driver package is unfree; must be explicitly allowed at eval time.
      allowUnfree = true;
      nvidia.acceptLicense = true;
    };

    hardware = {
      nvidia = {
        open = false;
        nvidiaSettings = true;
        # Needed for DRM/KMS path used by modern Wayland compositors.
        modesetting.enable = true;
        package = nvidiaDriverChannel;

        powerManagement = {
          enable = true;
          finegrained = lib.mkDefault false;
        };
      };

      graphics = {
        enable = true;
        package = nvidiaDriverChannel;
        # Steam/Proton and legacy 32-bit apps.
        enable32Bit = true;
        # Runtime codec/GL/Vulkan userspace helpers.
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
          libva-vdpau-driver
          libvdpau-va-gl
          mesa
          egl-wayland
          vulkan-loader
          libva
        ];
      };
    };

    nix.settings = {
      # Speeds up NVIDIA/CUDA-related binary fetches.
      substituters = ["https://cuda-maintainers.cachix.org"];

      trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };

    environment.systemPackages = with pkgs; [
      vulkan-tools
      mesa-demos
      libva-utils
    ];

    # NVIDIA application profile for Niri — fixes VRAM leak causing progressive
    # rendering degradation. See: https://github.com/YaLTeR/niri/wiki/Nvidia
    environment.etc."nvidia/nvidia-application-profiles-rc.d/50-niri-vram-fix.json".text =
      builtins.toJSON
      {
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
