{
  pkgs,
  stateVersion,
  hostname,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../nixos/modules
    ../../themes/catppuccin.nix
  ];

  boot.kernelParams = [
    # Force use of the thinkpad_acpi driver for backlight control.
    # This allows the backlight save/load systemd service to work.
    "acpi_backlight=native"
  ];

  networking.hostName = hostname;
  powerManagement.enable = true;
  programs.gamemode.enable = false;

  services = {
    power-profiles-daemon.enable = false;
    throttled.enable = lib.mkDefault true;
    libinput.enable = true;

    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
        CPU_SCALING_GOVERNOR_ON_BAT = "schedutil";

        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_power";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";

        PLATFORM_PROFILE_ON_AC = "low-power";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        USB_EXCLUDE_BTUSB = 1;

        RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
        RADEON_DPM_PERF_LEVEL_ON_BAT = "auto";

        DISK_IOSCHED = [ "none" ];

        # Battery charge thresholds for on-road usage
        START_CHARGE_THRESH_BAT0 = 85;
        STOP_CHARGE_THRESH_BAT0 = 90;
      };
    };
  };

  system = {
    inherit stateVersion;
    autoUpgrade.enable = true;
    autoUpgrade.dates = "weekly";
  };

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
      intelBusId = "PCI:00:02.0";
      # Dedicated
      nvidiaBusId = "PCI:02:00.0";
    };
  };

  environment.systemPackages = [ pkgs.home-manager ];
}
