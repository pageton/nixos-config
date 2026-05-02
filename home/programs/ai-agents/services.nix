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
  agentsSearch = pkgs.writeShellScriptBin "agents-search" ''
    exec ${scriptsDir}/ai/agents-search.sh "$@"
  '';
  findingsAndroid = pkgs.writeShellScriptBin "findings-android" ''
    exec ${scriptsDir}/ai/android-re/findings.sh "$@"
  '';
  findingsWeb = pkgs.writeShellScriptBin "findings-web" ''
    exec ${scriptsDir}/ai/web-re/findings.sh "$@"
  '';
  generateTotp = pkgs.writeShellScriptBin "generate-totp" ''
    exec ${scriptsDir}/ai/web-re/generate-totp.sh "$@"
  '';
  reDoctor = pkgs.writeShellScriptBin "re-doctor" ''
    exec ${scriptsDir}/ai/android-re/re-doctor.sh "$@"
  '';
  webReDoctor = pkgs.writeShellScriptBin "web-re-doctor" ''
    exec ${scriptsDir}/ai/web-re/web-re-doctor.sh "$@"
  '';
  androidReLaunchers = import ./android-re/_launchers.nix {
    inherit
      config
      constants
      lib
      pkgs
      ;
  };

  webReLaunchers = import ./web-re/_launchers.nix {
    inherit
      lib
      pkgs
      scriptsDir
      ;
  };

  omoProfiles = import ./helpers/_omo-profiles.nix { inherit config; };
  omoWrappers = map (profile:
    pkgs.writeShellScriptBin (builtins.replaceStrings ["-"] ["_"] profile.name) ''
      OPENCODE_CONFIG_DIR="${config.xdg.configHome}/${profile.name}" \
        exec opencode --log-level WARN "$@"
    ''
  ) omoProfiles.profiles;


  aliasLib = import ./helpers/_aliases.nix {
    inherit
      config
      constants
      lib
      pkgs
      ;
  };
  inherit (aliasLib) aiAliases aiAgentLauncher aiAgentInventory;
  mkCliAutoupdateScript = import ./helpers/_mk-cli-autoupdate-script.nix { inherit pkgs; };
  shellAliases = import ./helpers/_services-shell-aliases.nix { inherit cfg aiAliases constants; };

  forgePkg = inputs.forgecode.packages.${pkgs.stdenv.hostPlatform.system}.default;

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
      mkCliAutoupdateScript
      ;
  };
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      agentLogWrapper
      agentIter
      agentsSearch
      aiAgentLauncher
      aiAgentInventory
      pkgs.bubblewrap
      findingsAndroid
      findingsWeb
      generateTotp
      reDoctor
      webReDoctor
    ]
    ++ (lib.optional cfg.forge.enable forgePkg)
    ++ androidReLaunchers
    ++ webReLaunchers
    ++ omoWrappers
    ++ (lib.optional cfg.logging.enable (
      pkgs.writeShellScriptBin "ai-agent-log-cleanup" ''
        ${logCleanupCommand}
        echo "Cleaned up logs older than ${toString cfg.logging.retentionDays} days"
      ''
    ));

    home.sessionVariables = lib.mkIf cfg.opencode.enable { OPENCODE_EXPERIMENTAL_LSP_TOOL = "true"; };

    programs = import ../../../shared/alias-helpers.nix { inherit shellAliases; };

    systemd.user = aiSystemdUser;
  };
}
