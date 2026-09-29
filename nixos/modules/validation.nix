# Cross-module conflict assertions.
# Only real NixOS options here — module membership is decided by explicit
# imports in hosts/<name>/configuration.nix.
{ config, lib, ... }:
{
  assertions = [
    # === Power Management Daemon Conflicts ===
    {
      assertion = with config.services; !(tlp.enable && power-profiles-daemon.enable);
      message = "TLP and power-profiles-daemon cannot be enabled simultaneously. Choose one power management daemon.";
    }

    {
      assertion = with config.services; !(power-profiles-daemon.enable && thermald.enable);
      message = "power-profiles-daemon and thermald cannot be enabled simultaneously. They both manage thermal/power profiles.";
    }

    # === Audio Stack Conflicts ===
    {
      assertion = !(config.services.pulseaudio.enable && config.services.pipewire.enable);
      message = "PulseAudio and PipeWire cannot be enabled simultaneously. PipeWire provides a modern replacement for PulseAudio.";
    }

    # === Graphics Driver Conflicts ===
    {
      assertion = !(lib.elem "nouveau" config.boot.kernelModules && config.hardware.nvidia.enable);
      message = "NVIDIA proprietary and nouveau open-source drivers cannot coexist. Remove nouveau from boot.kernelModules.";
    }

    # === Display Manager Conflicts ===
    {
      assertion = !(config.services.displayManager.gdm.enable && config.services.greetd.enable);
      message = "GDM and greetd cannot be enabled simultaneously. Choose one display manager.";
    }

    # === Security Baseline ===
    {
      assertion = config.security.apparmor.enable;
      message = "AppArmor must be enabled (security.apparmor.enable = true) for mandatory access control.";
    }

    {
      assertion = with config.networking.firewall; enable;
      message = "Firewall must be enabled (networking.firewall.enable = true) for system security.";
    }

    # === Network Service Security ===
    {
      assertion = !config.services.avahi.enable || config.services.avahi.allowInterfaces != [ ];
      message = "Avahi must have explicit allowInterfaces list for security. Don't expose mDNS on all interfaces.";
    }
  ];
}
