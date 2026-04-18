# File cleanup services configuration.
# Opt-in only: broad automatic deletion can look like data loss.
{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let
  cfg = config.mySystem.cleanup;
in
{
  options.mySystem.cleanup = {
    enable = lib.mkEnableOption "automatic cleanup timers for downloads/cache";
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      services = {
        "cleanup-telegram-downloads" = {
          description = "Clean up old Telegram downloads";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c \"${pkgs.findutils}/bin/find '/home/${user}/Downloads/Telegram Desktop' -type f -mtime +14 -delete 2>/dev/null || true\"";
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

        "cleanup-pip-cache" = {
          description = "Clean up PIP package cache";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c 'if command -v pip >/dev/null 2>&1; then pip cache purge 2>/dev/null || true; fi'";
          };
        };

        "cleanup-playwright" = {
          description = "Clean up Playwright browser cache";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c \"${pkgs.findutils}/bin/find '/home/${user}/.cache/ms-playwright' -type f -mtime +30 -delete 2>/dev/null || true\"";
            ExecStartPost = "${pkgs.bash}/bin/bash -c \"${pkgs.findutils}/bin/find '/home/${user}/.cache/ms-playwright' -type d -empty -delete 2>/dev/null || true\"";
          };
        };

        "cleanup-bun-cache" = {
          description = "Clean up Bun package manager cache";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c 'if command -v bun >/dev/null 2>&1; then bun pm cache rm 2>/dev/null || true; fi'";
          };
        };

        "cleanup-go-cache" = {
          description = "Clean up Go modules cache";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c 'if command -v go >/dev/null 2>&1; then go clean -modcache 2>/dev/null || true; fi'";
          };
        };

        "cleanup-npm-cache" = {
          description = "Clean up npm cache";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c 'if command -v npm >/dev/null 2>&1; then npm cache clean --force 2>/dev/null || true; fi'";
          };
        };

        "cleanup-docker" = {
          description = "Clean up Docker system (preserves volumes, only when no containers running)";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "safe-docker-cleanup" ''
              #!${pkgs.bash}/bin/bash
              if ! ${pkgs.docker}/bin/docker info &>/dev/null; then
                echo "Docker daemon not running, skipping cleanup"
                exit 0
              fi
              running=$(${pkgs.docker}/bin/docker ps -q 2>/dev/null | wc -l)
              if [ "$running" -eq 0 ]; then
                echo "No containers running, proceeding with cleanup..."
                ${pkgs.docker}/bin/docker system prune --all --force
                echo "Docker cleanup completed (volumes preserved)"
              else
                echo "Skipping cleanup: $running container(s) currently running"
              fi
            '';
          };
        };

        "cleanup-screenshots" = {
          description = "Clean up old screenshots";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c \"${pkgs.findutils}/bin/find '/home/${user}/Screens' -type f -mtime +14 -delete 2>/dev/null || true\"";
            ExecStartPost = "${pkgs.bash}/bin/bash -c \"${pkgs.findutils}/bin/find '/home/${user}/Screens' -type d -empty -delete 2>/dev/null || true\"";
          };
        };

        "cleanup-telegram-desktop" = {
          description = "Clean up Telegram Desktop cached media";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c \"${pkgs.findutils}/bin/find '/home/${user}/.local/share/TelegramDesktop' -type f -mtime +60 -delete 2>/dev/null || true\"";
            ExecStartPost = "${pkgs.bash}/bin/bash -c \"${pkgs.findutils}/bin/find '/home/${user}/.local/share/TelegramDesktop' -type d -empty -delete 2>/dev/null || true\"";
          };
        };

        "cleanup-clipboard-history" = {
          description = "Clean up clipboard history (OPSEC - prevents sensitive data persistence)";
          serviceConfig = {
            Type = "oneshot";
            User = user;
            ExecStart = "${pkgs.bash}/bin/bash -c 'if [ -d /home/${user}/.cache/cliphist ]; then ${pkgs.cliphist}/bin/cliphist wipe && rm -f /home/${user}/.cache/cliphist/db; fi'";
          };
        };
      };

      timers = {
        "cleanup-telegram-downloads" = {
          description = "Timer for Telegram downloads cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };

        "cleanup-downloads" = {
          description = "Timer for general downloads cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "weekly";
            Persistent = true;
            RandomizedDelaySec = "2h";
          };
        };

        "cleanup-cache" = {
          description = "Timer for cache cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "weekly";
            Persistent = true;
            RandomizedDelaySec = "3h";
          };
        };

        "cleanup-pip-cache" = {
          description = "Timer for PIP cache cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "weekly";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };

        "cleanup-playwright" = {
          description = "Timer for Playwright cache cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
            RandomizedDelaySec = "2h";
          };
        };

        "cleanup-bun-cache" = {
          description = "Timer for Bun cache cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };

        "cleanup-go-cache" = {
          description = "Timer for Go cache cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };

        "cleanup-npm-cache" = {
          description = "Timer for npm cache cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
            RandomizedDelaySec = "1h";
          };
        };

        "cleanup-docker" = {
          description = "Timer for Docker cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
            RandomizedDelaySec = "2h";
          };
        };

        "cleanup-screenshots" = {
          description = "Timer for screenshots cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
            RandomizedDelaySec = "2h";
          };
        };

        "cleanup-telegram-desktop" = {
          description = "Timer for Telegram Desktop cache cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
            RandomizedDelaySec = "3h";
          };
        };

        "cleanup-clipboard-history" = {
          description = "Timer for clipboard history cleanup";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "daily";
            Persistent = true;
            RandomizedDelaySec = "6h";
          };
        };
      };
    };

    system.activationScripts = {
      createUserDirs = {
        text = ''
          mkdir -p /home/${user}/Downloads/Telegram\ Desktop
          mkdir -p /home/${user}/Screens
          chown ${user}:users /home/${user}/Downloads/Telegram\ Desktop
          chown ${user}:users /home/${user}/Screens
        '';
        deps = [ ];
      };
    };
  };
}
