# Idle management is owned by DMS so its lock screen, fade, inhibitors, and
# power-source-aware timeouts share one state machine.
{
  services.swayidle.enable = false;

  programs.dank-material-shell.settings = {
    # Values are seconds and match DMS's supported Settings UI presets.
    acLockTimeout = 600;
    batteryLockTimeout = 600;
    acMonitorTimeout = 1200;
    batteryMonitorTimeout = 1200;
    lockBeforeSuspend = true;
    fadeToLockEnabled = true;
    fadeToLockGracePeriod = 5;
    fadeToDpmsEnabled = true;
    fadeToDpmsGracePeriod = 5;
  };
}
