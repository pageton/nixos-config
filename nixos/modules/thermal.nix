# AMD thermal management for Ryzen 5 7600X.
# The firmware doesn't export ACPI thermal zones, so the kernel never throttles.
# This module provides software-defined thermal control via thermald.
{
  lib,
  pkgs,
  ...
}:

let
  # Thermal configuration for AMD Ryzen 5 7600X using k10temp hwmon sensor.
  # Previous config used x86_pkg_temp + intel_powerclamp (Intel-only) —
  # thermald silently failed: "invalid sensor type x86_pkg_temp".
  #
  # Tctl on AM5 includes a ~30°C offset. Real temp ≈ Tctl - 30.
  #   Tctl 80°C → die ~50°C (comfortable)
  #   Tctl 90°C → die ~60°C (warm, throttle proactively)
  #   Tctl 95°C → die ~65°C (AMD spec limit, hardware throttles)
  #
  # Verify sensor path with:
  #   cat /sys/class/hwmon/hwmon*/name   → find "k10temp"
  #   cat /sys/class/hwmon/hwmon2/temp1_input  → current Tctl in millidegC
  thermaldConfig = pkgs.writeText "thermal-conf.xml" ''
    <?xml version="1.0"?>
    <ThermalConfiguration>
      <Platform>
        <Name>AMD Ryzen 5 7600X</Name>
        <ProductName>*</ProductName>
        <ThermalZones>
          <ThermalZone>
            <Type>CPU</Type>
            <TripPoints>
              <TripPoint>
                <SensorType>hwmon</SensorType>
                <SensorPath>/sys/class/hwmon/hwmon2/temp1_input</SensorPath>
                <Temperature>85000</Temperature>
                <type>passive</type>
                <CoolingDevice>
                  <type>Processor</type>
                  <influence>100</influence>
                </CoolingDevice>
              </TripPoint>
              <TripPoint>
                <SensorType>hwmon</SensorType>
                <SensorPath>/sys/class/hwmon/hwmon2/temp1_input</SensorPath>
                <Temperature>90000</Temperature>
                <type>passive</type>
                <CoolingDevice>
                  <type>Processor</type>
                  <influence>100</influence>
                </CoolingDevice>
              </TripPoint>
              <TripPoint>
                <SensorType>hwmon</SensorType>
                <SensorPath>/sys/class/hwmon/hwmon2/temp1_input</SensorPath>
                <Temperature>93000</Temperature>
                <type>passive</type>
                <CoolingDevice>
                  <type>Processor</type>
                  <influence>100</influence>
                </CoolingDevice>
              </TripPoint>
            </TripPoints>
          </ThermalZone>
        </ThermalZones>
      </Platform>
    </ThermalConfiguration>
  '';
in
{
  # amd-pstate-epp is already active — confirm with:
  #   cat /sys/devices/system/cpu/amd_pstate/status
  # Prefer power-saving EPP to let the governor idle cores aggressively.
  boot.kernelParams = [ "amd_pstate.shared_mem=1" ];

  # Bias toward power efficiency; boost still available on demand.
  powerManagement.cpuFreqGovernor = "powersave";

  hardware.cpu.amd.updateMicrocode = lib.mkDefault true;

  # thermald — active thermal daemon that monitors temps and applies
  # CPU frequency clamping when trip points are hit.
  services.thermald = {
    enable = true;
    configFile = thermaldConfig;
  };
}
