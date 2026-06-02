{
  cfg,
  config,
  lib,
  pkgs,
  hmSystemdHelpers,
  logCleanupCommand,
  mkCliAutoupdateScript,
  autoUpdateTools,
}:
let
  inherit (hmSystemdHelpers) mkWeeklyTimer;
  agentmemoryRuntime = import ./_agentmemory-runtime.nix { inherit pkgs; };
  mkAutoUpdateService =
    {
      binary,
      npmPackage,
      label,
    }:
    {
      Unit.Description = "Auto-update ${label}";
      Service = {
        Type = "oneshot";
        ExecStart = "${mkCliAutoupdateScript { inherit binary npmPackage label; }}";
      };
    };
in
lib.mkMerge [
  (lib.mkIf cfg.agentmemory.enable {
    services.agentmemory = {
      Unit = {
        Description = "Shared persistent memory server for AI agents";
        After = [ "network-online.target" ];
      };
      Service = {
        Type = "simple";
        WorkingDirectory = "%h";
        Environment = [
          "AGENTMEMORY_URL=${cfg.agentmemory.url}"
          "CI=1"
          "NPM_CONFIG_CACHE=%h/.cache/npm"
          "PATH=${agentmemoryRuntime.iiiEngine}/bin:${pkgs.nodejs_22}/bin:/run/current-system/sw/bin"
        ];
        ExecStart = "${pkgs.nodejs_22}/bin/npx -y @agentmemory/agentmemory@${cfg.agentmemory.version}";
        Restart = "always";
        RestartSec = "10s";
        TimeoutStartSec = "300";
        TimeoutStopSec = "30";
      };
      Install.WantedBy = [ "default.target" ];
    };
  })
  # ── AI agents resource slice (always active when agents enabled) ──
  # Caps collective memory of all agent processes so they cannot starve
  # the compositor, terminal, or browser during large output generation.
  {
    slices.ai-agents = {
      Unit.Description = "AI agent processes — memory-constrained";
      Slice = {
        MemoryHigh = "8G"; # throttle at 8 GB
        MemoryMax = "10G"; # hard kill at 10 GB
        MemorySwapMax = "2G"; # limit swap usage
      };
    };
  }

  # ── Logging-gated services and timers ──
  (lib.mkIf cfg.logging.enable {
    tmpfiles.rules = [ "d ${cfg.logging.directory} 0755 - - -" ];

    services = {
      ai-agent-log-cleanup = {
        Unit.Description = "Clean up old AI agent logs";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.writeShellScript "cleanup" logCleanupCommand}";
        };
      };

      opencode-db-vacuum = {
        Unit.Description = "Vacuum OpenCode SQLite database";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.writeShellScript "opencode-vacuum" ''
            DB="${config.xdg.dataHome}/opencode/opencode.db"
            if [[ -f "$DB" ]]; then
              ${pkgs.sqlite}/bin/sqlite3 "$DB" "VACUUM;"
              echo "Vacuumed OpenCode database"
            fi
          ''}";
        };
      };
    }
    // builtins.listToAttrs (
      map (tool: lib.nameValuePair "${tool.binary}-autoupdate" (mkAutoUpdateService tool)) autoUpdateTools
    );

    timers = {
      ai-agent-log-cleanup = mkWeeklyTimer { description = "Weekly AI agent log cleanup"; };
      opencode-db-vacuum = mkWeeklyTimer { description = "Weekly OpenCode database vacuum"; };
    }
    // builtins.listToAttrs (
      map (
        tool:
        lib.nameValuePair "${tool.binary}-autoupdate" (mkWeeklyTimer {
          description = "Weekly ${tool.label} auto-update";
        })
      ) autoUpdateTools
    );
  })
]
