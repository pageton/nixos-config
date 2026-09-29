# NVIDIA Optimus (hybrid graphics) for ThinkPad.
# Bus IDs in NixOS format (PCI:bus:device:function), hex-free.
# Verify with: lspci | grep -E 'VGA|3D'
{ lib, ... }:
{
  hardware.nvidia = {
    powerManagement = {
      enable = true;
      finegrained = true; # CRITICAL for battery life
    };

    prime = {
      intelBusId = "PCI:0:2:0:0";
      nvidiaBusId = "PCI:2:0:0:0";

      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      sync.enable = false;
    };
  };
}
