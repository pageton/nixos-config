# TLP (Linux Advanced Power Management) configuration for ThinkPad.
# This module configures TLP, a power management daemon that optimizes
# power consumption and performance on laptops, with settings tuned for ThinkPad hardware.

{
  services = {
    tlp = {
      enable = true; # Enable TLP power management daemon

      settings = {
        # CPU Performance - CRITICAL for battery life
        CPU_SCALING_GOVERNOR_ON_AC = "performance"; # Full performance on AC
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave"; # Power saving on battery

        CPU_ENERGY_PERF_POLICY_ON_AC = "performance"; # Full performance on AC
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power"; # Aggressive power saving on battery

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 50; # Limit to 50% on battery (20-30% savings)

        CPU_BOOST_ON_AC = 1; # Enable turbo boost on AC
        CPU_BOOST_ON_BAT = 0; # Disable turbo boost on battery (20-30% savings)

        # Platform power profile settings
        PLATFORM_PROFILE_ON_AC = "performance"; # Full performance on AC
        PLATFORM_PROFILE_ON_BAT = "low-power"; # Low power on battery

        # CRITICAL for ThinkPad battery longevity (75-80% optimal range)
        START_CHARGE_THRESH_BAT0 = 75; # Start charging at 75%
        STOP_CHARGE_THRESH_BAT0 = 80; # Stop at 80% (doubles battery lifespan)

        # Wireless power management
        WIFI_PWR_ON_AC = "off"; # Full power on AC
        WIFI_PWR_ON_BAT = "on"; # Power saving on battery

        # Runtime power management for devices
        RUNTIME_PM_ON_AC = "on"; # Enable on AC
        RUNTIME_PM_ON_BAT = "auto"; # Auto-manage on battery

        # Disk power management
        DISK_IDLE_SECS_ON_AC = 0; # No idle timeout on AC
        DISK_IDLE_SECS_ON_BAT = 2; # Spin down after 2 seconds on battery

        # USB autosuspend (saves power)
        USB_AUTOSUSPEND = 1; # Enable USB autosuspend
        USB_BLACKLIST_PHONE = 1; # Don't suspend phones
        USB_EXCLUDE_BTUSB = 1; # Exclude Bluetooth USB devices

        # AMD Radeon graphics power management (if applicable)
        RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
        RADEON_DPM_PERF_LEVEL_ON_BAT = "low"; # Low power on battery

        # Disk I/O scheduler settings for SSDs
        DISK_IOSCHED = [ "none" ]; # Use none scheduler for SSDs

        # Additional power saving features
        RESTORE_DEVICE_STATE_ON_STARTUP = 1; # Restore device states
        DEVICES_TO_DISABLE_ON_STARTUP = "bluetooth wifi wwan"; # Disable on startup
        DEVICES_TO_ENABLE_ON_STARTUP = "wifi"; # Re-enable wifi if needed

        # Intel graphics power (if applicable)
        INTEL_GPU_MIN_FREQ_ON_AC = 300;
        INTEL_GPU_MIN_FREQ_ON_BAT = 300;
        INTEL_GPU_MAX_FREQ_ON_AC = 1200;
        INTEL_GPU_MAX_FREQ_ON_BAT = 600; # Limit GPU frequency on battery
      };
    };
  };
}
