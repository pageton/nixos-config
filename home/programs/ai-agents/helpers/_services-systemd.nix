{
  cfg,
  config,
  lib,
  pkgs,
  hmSystemdHelpers,
  logCleanupCommand,
  autoUpdate,
  agentmemoryRuntime,
}:
let
  inherit (hmSystemdHelpers) mkWeeklyTimer;
  bunPackage = import ../../../_helpers/_bun-package.nix { inherit pkgs; };
  # All agent CLI updates in ONE serialized oneshot. Per-tool services fired
  # concurrently (same weekly OnCalendar / same boot on Persistent catch-up)
  # and raced on bun's global package.json: last writer won, bun pruned the
  # other tools' packages, and ~/.bun/bin kept broken symlinks. Each tool's
  # script exits 1 on install failure without aborting the rest.
  aiAgentsAutoupdate = pkgs.writeShellScript "ai-agents-autoupdate" (
    ''
      fail=0
    ''
    + lib.concatMapStringsSep "\n" (
      tool: "${toString (autoUpdate.mkScript tool)} || fail=1"
    ) autoUpdate.tools
    + ''

      exit $fail
    ''
  );
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
          "BUN_INSTALL_CACHE_DIR=%h/.cache/bun"
          "PATH=${agentmemoryRuntime.iiiEngine}/bin:${bunPackage}/bin:/run/current-system/sw/bin"
        ];
        ExecStart = "${bunPackage}/bin/bunx @agentmemory/agentmemory@${cfg.agentmemory.version}";
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

  # ── Serialized CLI auto-update (agents enabled) ──
  # Not gated on cfg.logging: updates must run whenever the agents exist, or
  # a logging-disabled host silently loses every CLI after a global prune.
  (lib.mkIf cfg.enable {
    services.ai-agents-autoupdate = {
      Unit = {
        Description = "Install/update all AI agent CLIs (serialized)";
        # Boot-time Persistent catch-up can precede full network readiness;
        # the per-tool retry loop inside the script covers the residual gap.
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${aiAgentsAutoupdate}";
        # Worst case: 14 tools x 3 attempts x 15s backoff + installs.
        TimeoutStartSec = "30m";
      };
    };
    timers.ai-agents-autoupdate = mkWeeklyTimer {
      description = "Weekly AI agent CLI updates";
      randomizedDelaySec = "15m";
    };
  })

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
    };

    timers = {
      ai-agent-log-cleanup = mkWeeklyTimer { description = "Weekly AI agent log cleanup"; };
      opencode-db-vacuum = mkWeeklyTimer { description = "Weekly OpenCode database vacuum"; };
    };
  })
]
