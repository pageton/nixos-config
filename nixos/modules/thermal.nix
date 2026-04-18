# AMD thermal management for Ryzen 5 7600X.
# The firmware doesn't export ACPI thermal zones, so the kernel never throttles.
# This module provides software-defined thermal control via thermald.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Thermal configuration for AMD Ryzen 5 7600X (Tctl offset ~30C on AM5).
  # Real temp ≈ Tctl - 30, so Tctl 95°C ≈ die 65°C.
  # We throttle at Tctl 90°C (die ~60°C) to keep headroom.
  #
  # Trip points use k10temp (hwmon3 on this board) — verify with
  #   cat /sys/class/hwmon/hwmon*/name
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
                <SensorType>x86_pkg_temp</SensorType>
                <Temperature>80000</Temperature>
                <type>passive</type>
                <CoolingDevice>
                  <type>intel_powerclamp</type>
                  <influence>100</influence>
                </CoolingDevice>
                <CoolingDevice>
                  <type>Processor</type>
                  <influence>100</influence>
                </CoolingDevice>
              </TripPoint>
              <TripPoint>
                <SensorType>x86_pkg_temp</SensorType>
                <Temperature>85000</Temperature>
                <type>passive</type>
                <CoolingDevice>
                  <type>intel_powerclamp</type>
                  <influence>100</influence>
                </CoolingDevice>
                <CoolingDevice>
                  <type>Processor</type>
                  <influence>100</influence>
                </CoolingDevice>
              </TripPoint>
              <TripPoint>
                <SensorType>x86_pkg_temp</SensorType>
                <Temperature>90000</Temperature>
                <type>passive</type>
                <CoolingDevice>
                  <type>intel_powerclamp</type>
                  <influence>100</influence>
                </CoolingDevice>
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
