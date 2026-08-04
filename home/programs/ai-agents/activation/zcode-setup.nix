# ZCode activation — installs managed agents, hooks, and the orchestration MCP server.

{
  cfg,
  constants,
  pkgs,
  lib,
  toJSON,
}:
lib.mkIf cfg.zcode.enable (
  let
    jq = "${pkgs.jq}/bin/jq";
    cmp = "${pkgs.diffutils}/bin/cmp";
    orchestratorCfg = cfg.zcode.orchestrator;
    validManagedName = name: builtins.match "^[a-z0-9][a-z0-9_-]{2,63}$" name != null;
    agentNames = builtins.attrNames cfg.zcode.agents;
    commandNames = builtins.attrNames cfg.zcode.commands;
    invalidAgentNames = builtins.filter (name: !validManagedName name) agentNames;
    invalidCommandNames = builtins.filter (name: !validManagedName name) commandNames;

    zcodeDrv = builtins.head (import ../../../packages/custom/zcode.nix { inherit pkgs; });
    zcodeCliContents = zcodeDrv.appContents;
    zcodeCli = pkgs.writeShellScriptBin "zcode-agent-cli" ''
      exec ${pkgs.nodejs}/bin/node ${zcodeCliContents}/resources/glm/zcode.cjs "$@"
    '';
    orchestratorSources = pkgs.runCommand "zcode-orchestrator-${zcodeDrv.version}-sources" { } ''
      install -Dm755 ${../../../../scripts/ai/zcode-orchestrator.mjs} $out/lib/zcode-orchestrator.mjs
      install -Dm644 ${../../../../scripts/ai/zcode-orchestrator-core.mjs} $out/lib/zcode-orchestrator-core.mjs
      install -Dm644 ${../../../../scripts/ai/zcode-hook-runtime.mjs} $out/lib/zcode-hook-runtime.mjs
    '';
    orchestratorPackage = pkgs.writeShellApplication {
      name = "zcode-orchestrator";
      runtimeInputs = [
        pkgs.bubblewrap
        pkgs.coreutils
        pkgs.git
        pkgs.nodejs
        zcodeCli
      ];
      text = ''
        export ZCODE_ORCHESTRATOR_ENTRY_SCRIPT=${orchestratorSources}/lib/zcode-orchestrator.mjs
        export ZCODE_ORCHESTRATOR_NODE=${pkgs.nodejs}/bin/node
        export ZCODE_ORCHESTRATOR_ZCODE_CLI=${zcodeCli}/bin/zcode-agent-cli
        export ZCODE_ORCHESTRATOR_GIT=${pkgs.git}/bin/git
        export ZCODE_ORCHESTRATOR_BWRAP=${pkgs.bubblewrap}/bin/bwrap
        export ZCODE_ORCHESTRATOR_MODEL=${lib.escapeShellArg constants.services.zai.models.sonnet}
        export ZCODE_ORCHESTRATOR_BASE_URL=${lib.escapeShellArg "${constants.services.zai.apiRoot}/anthropic"}
        export ZCODE_ORCHESTRATOR_MAX_READERS=${toString orchestratorCfg.maxReaders}
        export ZCODE_ORCHESTRATOR_MAX_RUNS=${toString orchestratorCfg.maxActiveRuns}
        export ZCODE_ORCHESTRATOR_MAX_DEPTH=${toString orchestratorCfg.maxDepth}
        export ZCODE_ORCHESTRATOR_AGENT_TIMEOUT_MS=${toString orchestratorCfg.agentTimeoutMs}
        export ZCODE_ORCHESTRATOR_RUN_TIMEOUT_MS=${toString orchestratorCfg.runTimeoutMs}
        ${lib.optionalString (orchestratorCfg.hookConfigFile != null) ''
          export ZCODE_ORCHESTRATOR_HOOK_CONFIG=${lib.escapeShellArg orchestratorCfg.hookConfigFile}
        ''}
        exec ${pkgs.nodejs}/bin/node ${orchestratorSources}/lib/zcode-orchestrator.mjs "$@"
      '';
    };

    nativeHookExecutor = {
      type = "command";
      command = "${orchestratorPackage}/bin/zcode-orchestrator --native-hook";
      timeoutMs = 310000;
      enabled = true;
    };
    matchedNativeHook = {
      matcher = "*";
      hooks = [ nativeHookExecutor ];
    };
    unfilteredNativeHook = {
      hooks = [ nativeHookExecutor ];
    };
    nativeHookEvents = {
      SessionStart = [ unfilteredNativeHook ];
      UserPromptSubmit = [ unfilteredNativeHook ];
      PreToolUse = [ matchedNativeHook ];
      PermissionRequest = [ matchedNativeHook ];
      PostToolUse = [ matchedNativeHook ];
      PostToolUseFailure = [ matchedNativeHook ];
      Stop = [ unfilteredNativeHook ];
    };
    managedHookEvents =
      cfg.zcode.hooks
      // lib.optionalAttrs orchestratorCfg.enable (
        lib.mapAttrs (event: entries: (cfg.zcode.hooks.${event} or [ ]) ++ entries) nativeHookEvents
      );
    managedMcpServers = lib.optionalAttrs orchestratorCfg.enable {
      zcode-orchestrator = {
        command = "${orchestratorPackage}/bin/zcode-orchestrator";
        args = [ ];
        enabled = true;
      };
    };
    zcodeConfigFile = pkgs.writeText "zcode-config.json" (toJSON {
      hooks = {
        enabled = true;
        timeoutMs = 60000;
        maxOutputBytes = 32768;
        events = managedHookEvents;
      };
      mcp.servers = managedMcpServers;
    });

    mkMarkdownInstallScript =
      files:
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList (name: source: ''
          managed_target="$managed_dir/${name}.md"
          managed_tmp="$managed_target.tmp"

          if [[ -f "$managed_target" ]] && [[ ! -L "$managed_target" ]] && ${cmp} -s "${source}" "$managed_target"; then
            :
          else
            rm -f "$managed_tmp"
            cp "${source}" "$managed_tmp"
            chmod 644 "$managed_tmp"
            mv "$managed_tmp" "$managed_target"
          fi
        '') files
      );
    agentFiles =
      assert lib.assertMsg (
        invalidAgentNames == [ ]
      ) "Invalid ZCode agent names: ${lib.concatStringsSep ", " invalidAgentNames}";
      lib.mapAttrs (name: content: pkgs.writeText "zcode-agent-${name}.md" content) cfg.zcode.agents;
    commandFiles =
      assert lib.assertMsg (
        invalidCommandNames == [ ]
      ) "Invalid ZCode command names: ${lib.concatStringsSep ", " invalidCommandNames}";
      lib.mapAttrs (name: content: pkgs.writeText "zcode-command-${name}.md" content) cfg.zcode.commands;
    agentInstallScript = mkMarkdownInstallScript agentFiles;
    commandInstallScript = mkMarkdownInstallScript commandFiles;
    agentCount = builtins.length agentNames;
    commandCount = builtins.length commandNames;
    managedAgentNames = lib.concatStringsSep "\n" agentNames;
    managedCommandNames = lib.concatStringsSep "\n" commandNames;
    agentNamesFile = pkgs.writeText "zcode-current-agent-names" managedAgentNames;
    commandNamesFile = pkgs.writeText "zcode-current-command-names" managedCommandNames;
    legacyAgentNames = [
      "android-recon"
      "git-agent"
      "github-agent"
      "go-reviewer"
      "nix-verifier"
      "security-reviewer"
      "tmux-agent"
    ];
    legacyAgentCleanup = lib.concatMapStringsSep "\n" (name: ''
      rm -f "$agents_dir/${name}.md"
    '') legacyAgentNames;
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_dir="$HOME/.zcode/cli"
    target="$config_dir/config.json"
    mkdir -p "$config_dir"
    agents_dir="$HOME/.zcode/agents"
    commands_dir="$HOME/.zcode/commands"
    mkdir -p "$agents_dir" "$commands_dir"
    managed_state_dir="$HOME/.local/state/ai-agents"
    managed_agent_names_file="$managed_state_dir/zcode-managed-agents"
    managed_command_names_file="$managed_state_dir/zcode-managed-commands"
    mkdir -p "$managed_state_dir"

    if [[ -f "$target" ]] && [[ ! -L "$target" ]]; then
      ${jq} -s --argjson orchestrator_enabled ${builtins.toJSON orchestratorCfg.enable} '
        (.[1].hooks) as $hooks
        | .[0] * .[1]
        | .hooks = $hooks
        | if $orchestrator_enabled then . else del(.mcp.servers["zcode-orchestrator"]) end
      ' "$target" "${zcodeConfigFile}" > "$target.tmp"
      if ${cmp} -s "$target" "$target.tmp"; then
        rm -f "$target.tmp"
      else
        mv "$target.tmp" "$target"
      fi
    else
      rm -f "$target"
      cp "${zcodeConfigFile}" "$target"
      chmod 644 "$target"
    fi

    cleanup_retired_managed_files() {
      local manifest="$1"
      local directory="$2"
      local current_names="$3"

      if [[ -f "$manifest" ]]; then
        while IFS= read -r managed_name; do
          if [[ "$managed_name" =~ ^[a-z0-9][a-z0-9_-]{2,63}$ ]] && ! ${pkgs.gnugrep}/bin/grep -Fxq "$managed_name" "$current_names"; then
            rm -f "$directory/$managed_name.md"
          fi
        done < "$manifest"
      fi
    }

    ${legacyAgentCleanup}
    cleanup_retired_managed_files "$managed_agent_names_file" "$agents_dir" ${agentNamesFile}
    cleanup_retired_managed_files "$managed_command_names_file" "$commands_dir" ${commandNamesFile}

    managed_dir="$agents_dir"
    ${agentInstallScript}
    managed_dir="$commands_dir"
    ${commandInstallScript}

    cp ${pkgs.writeText "zcode-managed-agent-names" managedAgentNames} "$managed_agent_names_file.tmp"
    chmod 600 "$managed_agent_names_file.tmp"
    mv "$managed_agent_names_file.tmp" "$managed_agent_names_file"
    cp ${pkgs.writeText "zcode-managed-command-names" managedCommandNames} "$managed_command_names_file.tmp"
    chmod 600 "$managed_command_names_file.tmp"
    mv "$managed_command_names_file.tmp" "$managed_command_names_file"

    echo "✓ ZCode hooks, orchestration MCP, ${toString agentCount} agents, and ${toString commandCount} commands configured"
  ''
)
