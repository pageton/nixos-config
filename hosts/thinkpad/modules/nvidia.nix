# NVIDIA for my thinkpad configuration additions

{
  hardware.nvidia = {
    powerManagement = {
      finegrained = false;
    };

    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      sync.enable = false;

      # Integrated
      intelBusId = "PCI:0@2:0:0";

      # Dedicated
      nvidiaBusId = "PCI:2@0:0:0";
    };
  };
}
