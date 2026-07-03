# AMD Ryzen thermal management for desktop (Ryzen 5 7600X).
# Opt-in via mySystem.amdRyzenThermal — desktop only.
#
# The firmware doesn't export ACPI thermal zones, so the kernel never throttles.
#
# Previous config used thermald with SensorType=hwmon, but thermald 2.5.11
# rejects "hwmon" as invalid sensor type and the engine init fails every boot.
# Instead, this module uses amd-pstate EPP for proactive power management
# and a lightweight thermal watchdog that clamps max CPU frequency on overheat.
#
# amd_pstate=active provides hardware-managed frequency scaling with EPP hints.
# Setting EPP to "power" biases aggressively toward efficiency while allowing
# boost on demand.
{
  lib,
  pkgs,
  config,
  ...
}:

let
  # Thermal watchdog: monitors k10temp and clamps max frequency when hot.
  # Restores full frequency when cooled back down.
  # Uses stable hwmon resolution via /sys/class/hwmon/hwmon*/name lookup.
  thermalWatchdog = pkgs.writeShellScript "thermal-watchdog" ''
    set -euo pipefail

    MAX_TEMP=85000
    COOL_TEMP=70000
    FREQ_LIMIT=2500000
    FULL_FREQ=""

    find_k10temp() {
      for d in /sys/class/hwmon/hwmon*; do
        if [ -f "$d/name" ] && [ "$(cat "$d/name")" = "k10temp" ]; then
          echo "$d/temp1_input"
          return 0
        fi
      done
      return 1
    }

    SENSOR=$(find_k10temp) || { echo "thermal-watchdog: k10temp sensor not found"; exit 1; }

    FULL_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq)
    THROTTLED=false

    while true; do
      TEMP=$(cat "$SENSOR")
      if [ "$TEMP" -ge "$MAX_TEMP" ] && [ "$THROTTLED" = false ]; then
        echo "thermal-watchdog: Tctl=$((TEMP/1000))°C >= $((MAX_TEMP/1000))°C, throttling to $((FREQ_LIMIT/1000000))GHz"
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
          echo "$FREQ_LIMIT" > "$cpu" 2>/dev/null || true
        done
        THROTTLED=true
      elif [ "$TEMP" -le "$COOL_TEMP" ] && [ "$THROTTLED" = true ]; then
        echo "thermal-watchdog: Tctl=$((TEMP/1000))°C <= $((COOL_TEMP/1000))°C, restoring full frequency"
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
          echo "$FULL_FREQ" > "$cpu" 2>/dev/null || true
        done
        THROTTLED=false
      fi
      sleep 2
    done
  '';
in
{
  options.mySystem.amdRyzenThermal = {
    enable = lib.mkEnableOption "AMD Ryzen thermal management (amd-pstate EPP + thermal watchdog, disables thermald)";
  };

  config = lib.mkIf config.mySystem.amdRyzenThermal.enable {
    boot.kernelParams = [ "amd_pstate=active" ];

    # Use powersave governor with EPP=power for maximum efficiency.
    # Boost remains available on demand for short bursts.
    powerManagement.cpuFreqGovernor = "powersave";

    hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

    # Thermal watchdog — clamps max CPU freq when Tctl exceeds 85°C,
    # restores when it cools below 70°C.
    systemd.services.thermal-watchdog = {
      description = "Thermal watchdog for AMD Ryzen 5 7600X";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = thermalWatchdog;
        Restart = "on-failure";
        RestartSec = 5;
        Nice = 19;
        IOSchedulingClass = "idle";
      };
    };

    # Set EPP to power on boot and after resume.
    systemd.services.set-amd-epp = {
      description = "Set AMD EPP to power mode";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.bash}/bin/bash -c 'for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do echo power > \"$f\" 2>/dev/null || true; done'";
        RemainAfterExit = true;
      };
    };

    # Disable thermald — it was silently failing with "invalid sensor type hwmon"
    # and "THD engine init failed" on every boot. The watchdog above replaces it.
    services.thermald.enable = false;
  };
}
