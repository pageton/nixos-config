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

  webReLaunchers = import ./web-re/_launchers.nix { inherit lib pkgs scriptsDir; };

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
  mkCliAutoupdateScript = import ./helpers/_mk-cli-autoupdate-script.nix { inherit pkgs; };
  shellAliases = import ./helpers/_services-shell-aliases.nix { inherit cfg aiAliases constants; };

  autoUpdateTools = [
    {
      binary = "claude";
      npmPackage = "@anthropic-ai/claude-code";
      label = "Claude Code CLI";
    }
    {
      binary = "opencode";
      npmPackage = "opencode-ai";
      label = "OpenCode CLI";
    }
    {
      binary = "codex";
      npmPackage = "@openai/codex";
      label = "Codex CLI";
    }
    {
      binary = "codegraph";
      npmPackage = "@colbymchenry/codegraph";
      label = "CodeGraph CLI";
    }
    {
      binary = "copilot";
      npmPackage = "@github/copilot";
      label = "GitHub Copilot CLI";
    }
  ];

  autoUpdateAllScript = pkgs.writeShellScript "update-ai-agents" (
    lib.concatMapStringsSep "\n" (tool: toString (mkCliAutoupdateScript tool)) autoUpdateTools
    + lib.optionalString cfg.serena.enable ''

      ${pkgs.uv}/bin/uv tool install -p 3.13 --prerelease=allow ${cfg.serena.package}@latest 2>/dev/null && echo "Updated Serena" || true
    ''
  );

  terax = pkgs.appimageTools.wrapType2 rec {
    pname = "terax";
    version = "0.6.6";

    src = pkgs.fetchurl {
      url = "https://github.com/crynta/terax-ai/releases/download/v${version}/Terax_${version}_amd64.AppImage";
      sha256 = "sha256-4Ns4tz/SjExIKUTP/Uo74JwyE5fEBRF9pHDzAjzDVL4=";
    };

    profile = lib.optionalString cfg.terax.disableDmabufRenderer ''
      export WEBKIT_DISABLE_DMABUF_RENDERER=1
    '';

    meta = with lib; {
      description = "AI-native terminal emulator built with Tauri";
      homepage = "https://terax.app";
      license = licenses.asl20;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [ pkgs.stdenv.hostPlatform.system ];
      mainProgram = "terax";
    };
  };

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
      mkCliAutoupdateScript
      autoUpdateTools
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
    ++ (lib.optional cfg.agentmemory.enable agentmemoryRuntime.iiiEngine)
    ++ (lib.optional cfg.terax.enable terax)
    ++ (lib.optional cfg.serena.enable serena)
    ++ androidReLaunchers
    ++ webReLaunchers
    ++ (lib.optional cfg.logging.enable (
      pkgs.writeShellScriptBin "ai-agent-log-cleanup" ''
        ${logCleanupCommand}
        echo "Cleaned up logs older than ${toString cfg.logging.retentionDays} days"
      ''
    ));

    home.sessionVariables = lib.mkMerge [
      (lib.mkIf cfg.opencode.enable { OPENCODE_EXPERIMENTAL_LSP_TOOL = "true"; })
    ];

    home.file = lib.mkIf cfg.terax.enable {
      ".local/share/applications/terax.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Terax
        Exec=terax %U
        Icon=utilities-terminal
        Comment=AI-native terminal emulator
        Categories=Development;TerminalEmulator;
      '';
    };

    programs = import ../../../shared/alias-helpers.nix { inherit shellAliases; };

    home.activation.updateAiAgentCLIs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${autoUpdateAllScript}
    '';

    systemd.user = aiSystemdUser;
  };
}
