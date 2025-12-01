# System stability and service conflict resolution.
# This module implements various stability improvements including memory management,
{ pkgsStable, ... }:
{
  services = {
    # Early OOM (Out of Memory) killer to prevent system lockups
    earlyoom = {
      enable = true; # Enable earlyoom service
      freeMemThreshold = 5; # Kill processes when free memory < 5%
      freeSwapThreshold = 10; # Kill processes when free swap < 10%
    };

    # D-Bus service configuration to reduce conflicts
    dbus = {
      # Additional D-Bus services for better integration
      packages = with pkgsStable; [ ];
    };
  };

  # Environment variables to improve application stability
  environment.sessionVariables = {
    # Disable WebKit compositing to reduce GPU-related crashes
    WEBKIT_DISABLE_COMPOSITING_MODE = "1";

    # Use always-malloc for GLib memory allocation to reduce fragmentation
    G_SLICE = "always-malloc";
  };
}
