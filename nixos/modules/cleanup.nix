# File cleanup services configuration.
# This module provides automated cleanup services for various directories
# to prevent disk space issues from accumulating temporary files.
{
  lib,
  pkgs,
  user,
  hostname,
  ...
}: {
  config = lib.mkIf (hostname != "server") {
    # Telegram downloads cleanup service
    systemd = {
      services = {
        "cleanup-telegram-downloads" = {
          description = "Clean up old Telegram downloads";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c \"${pkgs.findutils}/bin/find '/home/${user}/Downloads/Telegram Desktop' -type f -mtime +14 -delete 2>/dev/null || true\"";
            # Clean empty directories after removing files
            ExecStartPost = "${pkgs.bash}/bin/bash -c \"${pkgs.findutils}/bin/find '/home/${user}/Downloads/Telegram Desktop' -type d -empty -delete 2>/dev/null || true\"";
          };
        };

        "cleanup-downloads" = {
          description = "Clean up old general downloads";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.findutils}/bin/find /home/${user}/Downloads -type f -mtime +30 -delete 2>/dev/null || true'";
            ExecStartPost = "${pkgs.bash}/bin/bash -c '${pkgs.findutils}/bin/find /home/${user}/Downloads -type d -empty -delete 2>/dev/null || true'";
          };
        };

        "cleanup-cache" = {
          description = "Clean up user cache files";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/du -sh /home/${user}/.cache 2>/dev/null || true'";
            ExecStartPost = "${pkgs.bash}/bin/bash -c 'if [ -d /home/${user}/.cache ]; then ${pkgs.findutils}/bin/find /home/${user}/.cache -type f -mtime +30 -delete 2>/dev/null || true; fi'";
          };
        };
      };

      timers = {
        "cleanup-telegram-downloads" = {
          description = "Timer for Telegram downloads cleanup";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };

        "cleanup-downloads" = {
          description = "Timer for general downloads cleanup";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = "weekly";
            Persistent = true;
            RandomizedDelaySec = "2h";
          };
        };

        "cleanup-cache" = {
          description = "Timer for cache cleanup";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };
      };
    };

    # Ensure user directory exists
    system.activationScripts = {
      createUserDirs = {
        text = ''
          mkdir -p /home/${user}/Downloads/Telegram\ Desktop
          chown ${user}:users /home/${user}/Downloads/Telegram\ Desktop
        '';
        deps = [];
      };
    };
  };
}