# NVIDIA graphics configuration for ThinkPad.
# This module configures NVIDIA Optimus (hybrid graphics) for ThinkPad laptops,
# enabling proper switching between integrated Intel and dedicated NVIDIA GPUs.
{ lib, ... }:
{
  hardware.nvidia = {
    # Power management settings for NVIDIA GPU - CRITICAL for battery life
    powerManagement = {
      enable = true; # Enable NVIDIA power management
      finegrained = lib.mkForce true; # Fine-grained power control (30-50% battery savings)
    };

    # NVIDIA Optimus (PRIME) configuration for hybrid graphics
    prime = {
      # Enable offloading to dedicated GPU when needed
      offload = {
        enable = true; # Enable GPU offloading
        enableOffloadCmd = true; # Enable offload command
      };

      # Disable sync mode (use offload instead)
      sync.enable = false;

      # PCI bus IDs for graphics devices
      # Integrated Intel GPU
      intelBusId = "PCI:0@2:0:0";

      # Dedicated NVIDIA GPU
      nvidiaBusId = "PCI:2@0:0:0";
    };
  };
}
