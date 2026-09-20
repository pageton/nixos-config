# Codex configuration activation — generates ~/.codex/config.toml.

{
  cfg,
  pkgs,
  lib,
  sharedMcpServers,
}:
lib.mkIf cfg.codex.enable (
  let
    codexNotifyScript = pkgs.writeShellScript "codex-notify" ''
      set -euo pipefail

      payload=""
      for arg in "$@"; do
        if [[ -n "$arg" ]] && ${pkgs.jq}/bin/jq -e . >/dev/null 2>&1 <<< "$arg"; then
          payload="$arg"
          break
        fi
      done

      if [[ -z "$payload" ]]; then
        payload="$*"
      fi

      if [[ -z "$payload" ]] && [[ ! -t 0 ]]; then
        payload="$(cat)"
      fi

      summary="Codex"
      body="$payload"

      if [[ -n "$payload" ]] && ${pkgs.jq}/bin/jq -e . >/dev/null 2>&1 <<< "$payload"; then
        summary="$(${pkgs.jq}/bin/jq -r 'if type == "object" then (.title // .summary // "Codex") else "Codex" end' <<< "$payload")"
        body="$(${pkgs.jq}/bin/jq -r '
          if type == "object" then
            (.message // .body // ."last-assistant-message" // .content // .type // "Codex notification")
          else
            .
          end
        ' <<< "$payload")"
      fi

      body="$(printf '%s' "$body" | tr '\n' ' ')"
      body="$(printf '%s' "$body" | ${pkgs.gnused}/bin/sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')"
      if [[ -z "$body" ]]; then
        body="Notification"
      fi

      notify-send -a "Codex" -i dialog-information "$summary" "$body" 2>/dev/null || true
    '';
    mcpToml = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: server:
        let
          argsStr = lib.concatMapStringsSep ", " (a: ''"${a}"'') (server.args or [ ]);
          envSet = if (server.env or null) == null then { } else server.env;
          envLines = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: ''${k} = "${v}"'') envSet);
        in
        ''
          [mcp_servers.${name}]
          command = "${server.command}"
          args = [${argsStr}]
          enabled = true
        ''
        + lib.optionalString (envSet != { }) ''

          [mcp_servers.${name}.env]
          ${envLines}
        ''
      ) (lib.filterAttrs (_: s: s.enable && (s.type or "local") == "local") sharedMcpServers)
    );
    projectsToml = lib.concatMapStringsSep "\n" (path: ''
      [projects."${path}"]
      trust_level = "trusted"
    '') cfg.codex.trustedProjects;
    featuresToml = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: enabled: "${name} = ${lib.boolToString enabled}") cfg.codex.features
    );
    # Shared TOML field rendering for profiles and custom agents.
    mkEntityTomlFields =
      {
        model ? null,
        personality ? null,
        reasoningEffort ? null,
        approvalPolicy ? null,
        sandboxMode ? null,
        enableSearch ? false,
        developerInstructions ? "",
        extraToml ? "",
      }:
      lib.optional (model != null) ''model = "${model}"''
      ++ lib.optional (personality != null) ''personality = "${personality}"''
      ++ lib.optional (reasoningEffort != null) ''model_reasoning_effort = "${reasoningEffort}"''
      ++ lib.optional (approvalPolicy != null) ''approval_policy = "${approvalPolicy}"''
      ++ lib.optional (sandboxMode != null) ''sandbox_mode = "${sandboxMode}"''
      ++ lib.optional enableSearch "tools.web_search = true"
      ++ lib.optional (developerInstructions != "") ''
        developer_instructions = """
        ${developerInstructions}
        """
      ''
      ++ lib.optional (extraToml != "") extraToml;
    # Codex 0.134+ profiles are standalone $CODEX_HOME/<name>.config.toml layers
    # selected with `codex --profile <name>`; legacy [profiles.*] tables now make
    # `--profile` fail outright. Global instructions are appended to profile
    # developer_instructions so a profile never drops the shared rules.
    profileNames = builtins.attrNames cfg.codex.profiles;
    profileNamesArg = lib.concatMapStringsSep " " lib.escapeShellArg profileNames;
    renderProfileFile =
      name: profile:
      let
        devInstructions =
          if profile.developerInstructions == "" then
            ""
          else
            "${profile.developerInstructions}\n${cfg.globalInstructions}";
      in
      ''
        cat > "$HOME/.codex/${name}.config.toml" << 'CODEX_PROFILE_EOF'
        ${lib.concatStringsSep "\n" (mkEntityTomlFields {
          inherit (profile)
            model
            personality
            reasoningEffort
            approvalPolicy
            sandboxMode
            enableSearch
            extraToml
            ;
          developerInstructions = devInstructions;
        })}
        CODEX_PROFILE_EOF
        ${pkgs.gnused}/bin/sed -i 's/^        //' "$HOME/.codex/${name}.config.toml"
      '';
    profilesWrite = lib.concatStringsSep "\n" (lib.mapAttrsToList renderProfileFile cfg.codex.profiles);
    renderCustomAgent = name: agent: ''
      cat > "$HOME/.codex/agents/${name}.toml" << 'CODEX_AGENT_EOF'
      ${lib.concatStringsSep "\n" (
        [
          ''name = "${name}"''
          ''description = "${agent.description}"''
        ]
        ++ mkEntityTomlFields {
          inherit (agent)
            model
            reasoningEffort
            approvalPolicy
            sandboxMode
            enableSearch
            developerInstructions
            extraToml
            ;
        }
      )}
      CODEX_AGENT_EOF
      ${pkgs.gnused}/bin/sed -i 's/^        //' "$HOME/.codex/agents/${name}.toml"
    '';
    customAgentsWrite = lib.concatStringsSep "\n" (
      lib.mapAttrsToList renderCustomAgent cfg.codex.customAgents
    );
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.codex" "$HOME/.codex/agents"
    find "$HOME/.codex" -maxdepth 1 -name 'cx*.config.toml' -delete 2>/dev/null
    cat > "$HOME/.codex/config.toml" << 'CODEX_EOF'
    personality = "${cfg.codex.personality}"
    model = "${cfg.codex.model}"
    model_reasoning_effort = "${cfg.codex.reasoningEffort}"
    model_reasoning_summary = "concise"
    approval_policy = "${cfg.codex.approvalPolicy}"
    sandbox_mode = "${cfg.codex.sandboxMode}"
    web_search = "${if cfg.codex.enableSearch then "live" else "cached"}"
    allow_login_shell = false
    check_for_update_on_startup = true
    suppress_unstable_features_warning = true

    notify = ["${codexNotifyScript}"]

    developer_instructions = """
    Experienced developer. Concise communication, no preamble.
    Evidence-based decisions. Minimal changes - fix bugs without refactoring.
    Never suppress type errors. Never commit unless asked.
    Run diagnostics/tests on changed files before claiming done.
    Match existing codebase patterns and conventions.
    ${lib.optionalString (cfg.globalInstructions != "") cfg.globalInstructions}
    """

    [tui]
    animations = true
    notifications = true

    [history]
    persistence = "save-all"
    max_bytes = 52428800

    [features]
    ${featuresToml}

    ${mcpToml}
    ${projectsToml}

    [shell_environment_policy]
    inherit = "core"
    include_only = ["PATH", "HOME", "USER", "SHELL", "TERM", "EDITOR", "VISUAL", "LANG", "LC_ALL", "PWD"]
    exclude = ["AWS_*", "AZURE_*", "GCP_*", "ANTHROPIC_API_KEY", "OPENAI_API_KEY", "OPENROUTER_API_KEY"]

    ${cfg.codex.extraToml}
    CODEX_EOF
    ${pkgs.gnused}/bin/sed -i 's/^          //' "$HOME/.codex/config.toml"
    find "$HOME/.codex/agents" -maxdepth 1 -type f -name '*.toml' ! -name 'ecc-*.toml' -delete
    ${customAgentsWrite}

    # Profile layers: remove files for profiles that are no longer configured,
    # then write the current set. Tracked in .hm-managed-profiles so
    # user-created profiles are never deleted.
    managed_profiles="$HOME/.codex/.hm-managed-profiles"
    if [[ -f "$managed_profiles" ]]; then
      while IFS= read -r stale_profile; do
        [[ -n "$stale_profile" ]] || continue
        case " ${profileNamesArg} " in
          *" $stale_profile "*) ;;
          *) rm -f "$HOME/.codex/$stale_profile.config.toml" ;;
        esac
      done < "$managed_profiles"
    fi
    printf '%s\n' ${profileNamesArg} > "$managed_profiles"
    ${profilesWrite}
    echo "✓ Codex config.toml configured"
  ''
)
