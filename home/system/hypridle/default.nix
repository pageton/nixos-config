# Hypridle (idle management) configuration.
# This module configures Hypridle, a daemon for managing system idle behavior
# including screen dimming, locking, suspend, and display power management.

{
  services.hypridle = {
    enable = true; # Enable Hypridle idle management daemon

    settings = {
      # General idle management settings
      general = {
        before_sleep_cmd = "loginctl lock-session"; # Lock screen before sleep
        after_sleep_cmd = "sleep 2 && hyprctl dispatch dpms on"; # Turn on display after sleep with delay
        ignore_dbus_inhibit = false; # Respect D-Bus inhibit signals
        lock_cmd = "pidof hyprlock || hyprlock"; # Check if hyprlock is already running
      };

      # Idle timeout listeners with actions
      listener = [
        # Dim screen after 3 minutes of inactivity
        {
          timeout = 180; # 3 minutes
          on-timeout = "brightnessctl -s set 30"; # Dim to 30% brightness
          on-resume = "brightnessctl -r"; # Restore brightness on activity
        }

        # Lock screen after 8 minutes of inactivity
        {
          timeout = 500; # 8 minutes
          on-timeout = "loginctl lock-session"; # Lock the session
        }

        # Turn off display after 23 minutes of inactivity
        {
          timeout = 1400; # 23 minutes
          on-timeout = "hyprctl dispatch dpms off"; # Turn off display
          on-resume = "sleep 2 && hyprctl dispatch dpms on"; # Turn on display on activity with delay
        }

        # Suspend system after 37 minutes of inactivity
        {
          timeout = 2200; # 37 minutes
          on-timeout = "systemctl suspend"; # Suspend the system
        }
      ];
    };
  };
}
