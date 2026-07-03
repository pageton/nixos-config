# NVIDIA GPU drivers, CUDA, and Wayland integration.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  nvidiaDriverChannel = config.boot.kernelPackages.nvidiaPackages.stable;
in
{
  services.xserver.videoDrivers = [ "nvidia" ];

  boot.blacklistedKernelModules = [ "nouveau" ];

  environment.variables =
    let
      # On hybrid GPU laptops (PRIME offload), default to Intel/Mesa so the NVIDIA
      # dGPU can fully suspend (~0W) when no app requests it. On dedicated GPU
      # desktops, default to NVIDIA as the primary renderer.
      hybrid = config.hardware.nvidia.prime.offload.enable;
    in
    {
      XDG_SESSION_TYPE = "wayland";

      # Force GTK4 apps to use GL renderer instead of Vulkan.
      # Fixes black/broken windows with NVIDIA (VK_ERROR_OUT_OF_DATE_KHR).
      GSK_RENDERER = "gl";

      # ELECTRON_OZONE_PLATFORM_HINT is set in niri/main.nix (compositor-level)
      __GL_GSYNC_ALLOWED = "1";
      __GL_VRR_ALLOWED = "1";
      NVD_BACKEND = "direct";
      MOZ_ENABLE_WAYLAND = "1";
    }
    // (
      if hybrid then
        {
          # Intel/Mesa defaults — dGPU activates only via `nvidia-offload <cmd>`
          LIBVA_DRIVER_NAME = "iHD";
        }
      else
        {
          LIBVA_DRIVER_NAME = "nvidia";
          GBM_BACKEND = "nvidia-drm";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        }
    );

  nixpkgs.config = {
    allowUnfree = true;
    nvidia.acceptLicense = true;
  };

  hardware = {
    nvidia = {
      open = true;
      nvidiaSettings = true;
      modesetting.enable = true; # Required for Wayland compositors
      package = nvidiaDriverChannel;

      powerManagement = {
        enable = true;
        # finegrained configured in host-specific modules
      };
    };

    graphics = {
      enable = true;
      package = nvidiaDriverChannel;
      enable32Bit = true;

      extraPackages =
        with pkgs;
        [
          nvidia-vaapi-driver
          libva-vdpau-driver
          libvdpau-va-gl
          mesa
          egl-wayland
          vulkan-loader
          libva
        ]
        ++ lib.optionals config.hardware.nvidia.prime.offload.enable [
          intel-media-driver # Intel VA-API (iHD) for hybrid GPU video decode
        ];
    };
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
    libva-utils
  ];

  services.udev.extraRules = ''
    KERNEL=="nvidia*", GROUP="video", MODE="0660"
    KERNEL=="nvidiactl", GROUP="video", MODE="0660"
    KERNEL=="nvidia-modeset", GROUP="video", MODE="0660"
  '';
}
