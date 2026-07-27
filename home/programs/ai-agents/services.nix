# Packages, zsh aliases, systemd user services/timers, and log analysis for AI agents.

{
  config,
  constants,
  hmSystemdHelpers,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.aiAgents;
  scriptsDir = "${config.home.homeDirectory}/${constants.paths.scripts}";

  agentLogWrapper = pkgs.writeShellScriptBin "ai-agent-log-wrapper" ''
    AI_AGENT_LOG_DIR=${lib.escapeShellArg cfg.logging.directory} \
      AI_AGENT_NOTIFY_ON_ERROR=${if cfg.logging.notifyOnError then "true" else "false"} \
      exec ${scriptsDir}/ai/agent-log-wrapper.sh "$@"
  '';
  agentIter = pkgs.writeShellScriptBin "iter" (
    aliasLib.mkWorkflowEnvVars "bash ${scriptsDir}/ai/agent-iter.sh"
  );
  # Pure exec wrappers — each delegates to a script under scriptsDir.
  scriptWrappers =
    map
      (
        e:
        pkgs.writeShellScriptBin e.name ''
          exec ${scriptsDir}/${e.script} "$@"
        ''
      )
      [
        {
          name = "agents-search";
          script = "ai/agents-search.sh";
        }
        {
          name = "findings-android";
          script = "ai/android-re/findings.sh";
        }
        {
          name = "findings-web";
          script = "ai/web-re/findings.sh";
        }
        {
          name = "generate-totp";
          script = "ai/web-re/generate-totp.sh";
        }
        {
          name = "re-doctor";
          script = "ai/android-re/re-doctor.sh";
        }
        {
          name = "web-re-doctor";
          script = "ai/web-re/web-re-doctor.sh";
        }
      ];
  androidReLaunchers = import ./android-re/_launchers.nix {
    inherit
      config
      constants
      lib
      pkgs
      ;
  };

  webReLaunchers = import ./web-re/_launchers.nix { inherit lib pkgs scriptsDir; };

  mimoAndroidReLaunchers = import ./android-re/_mimo-launchers.nix {
    inherit
      config
      constants
      lib
      pkgs
      ;
  };

  mimoWebReLaunchers = import ./web-re/_mimo-launchers.nix { inherit lib pkgs scriptsDir; };

  aliasLib = import ./helpers/_aliases.nix {
    inherit
      config
      constants
      lib
      pkgs
      ;
  };
  inherit (aliasLib) aiAliases aiAgentLauncher aiAgentInventory;
  agentmemoryRuntime = import ./helpers/_agentmemory-runtime.nix { inherit pkgs; };
  autoUpdate = import ./helpers/_mk-cli-autoupdate-script.nix { inherit pkgs; };
  shellAliases = import ./helpers/_services-shell-aliases.nix { inherit cfg aiAliases constants; };
  zcodeDrv =
    let
      zcodeList = import ../../packages/custom/zcode.nix { inherit pkgs lib; };
    in
    builtins.head zcodeList;

  autoUpdateAllScript = pkgs.writeShellScript "update-ai-agents" (
    lib.concatMapStringsSep "\n" (tool: toString (autoUpdate.mkScript tool)) autoUpdate.tools
    + lib.optionalString cfg.serena.enable ''

      ${pkgs.uv}/bin/uv tool install -p 3.13 --prerelease=allow ${cfg.serena.package}@latest 2>/dev/null && echo "Updated Serena" || true
    ''
  );

  serena = pkgs.writeShellScriptBin "serena" ''
    if ! ${pkgs.uv}/bin/uv tool list 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q '${cfg.serena.package}'; then
      ${pkgs.uv}/bin/uv tool install -p 3.13 --prerelease=allow ${cfg.serena.package}@latest
    fi
    exec ${pkgs.uv}/bin/uv tool run ${cfg.serena.package} "$@"
  '';

  logCleanupCommand = ''
    find "${cfg.logging.directory}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete
    find "$HOME/${constants.paths.opencodeLogDir}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete 2>/dev/null || true
    find "$HOME/${constants.paths.codexLogDir}" -name "*.log" -mtime +${toString cfg.logging.retentionDays} -delete 2>/dev/null || true
  '';

  aiSystemdUser = import ./helpers/_services-systemd.nix {
    inherit
      cfg
      config
      lib
      pkgs
      hmSystemdHelpers
      logCleanupCommand
      autoUpdate
      agentmemoryRuntime
      ;
  };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      agentLogWrapper
      agentIter
      aiAgentLauncher
      aiAgentInventory
      pkgs.bubblewrap
    ]
    ++ scriptWrappers
    ++ (lib.optional cfg.agentmemory.enable agentmemoryRuntime.iiiEngine)
    ++ (lib.optional cfg.serena.enable serena)
    ++ (lib.optional cfg.speckit.enable pkgs.spec-kit)
    ++ androidReLaunchers
    ++ webReLaunchers
    ++ mimoAndroidReLaunchers
    ++ mimoWebReLaunchers
    ++ (lib.optional cfg.zcode.enable zcodeDrv)
    ++ (lib.optional cfg.logging.enable (
      pkgs.writeShellScriptBin "ai-agent-log-cleanup" ''
        ${logCleanupCommand}
        echo "Cleaned up logs older than ${toString cfg.logging.retentionDays} days"
      ''
    ));

    home.sessionVariables = lib.mkMerge [
      (lib.mkIf cfg.opencode.enable { OPENCODE_EXPERIMENTAL_LSP_TOOL = "true"; })
    ];

    programs.zsh.shellAliases = shellAliases;

    home.activation.updateAiAgentCLIs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD ${autoUpdateAllScript}
    '';
    systemd.user = aiSystemdUser;
  };
}
