# Secret patching activation — injects API keys and tokens into agent configs.

{
  cfg,
  pkgs,
  lib,
  config,
  constants,
  opencodeConfigPathList,
  opencodeZaiFilter,
  claudeZaiFilter,
  geminiZaiFilter,
  forgeZaiFilter,
  githubPlaceholderFilter,
  openrouterPlaceholderFilter,
  context7PlaceholderFilter,
  zaiProfileNames,
}:
let
  forgeProfiles = import ../helpers/_forge-profiles.nix { inherit config; };
  forgeMcpPathList = lib.concatMapStringsSep " " (
    name: "$HOME/.${name}/.mcp.json"
  ) forgeProfiles.names;

  piProfiles = import ../helpers/_pi-profiles.nix { inherit config; };
  piModelsPathList = lib.concatMapStringsSep " " (
    name: "$HOME/.omp/profiles/${name}/models.yml"
  ) piProfiles.names;

  zaiApiRoot = constants.services.zai.apiRoot;
in
lib.hm.dag.entryAfter
  [ "writeBoundary" "linkGeneration" "setupCodexConfig" "setupClaudeConfig" "setupForgeConfig" ]
  ''
    patch_json_file() {
      local file="$1"
      local arg_name="$2"
      local arg_value="$3"
      local filter="$4"

      ${pkgs.jq}/bin/jq --arg "$arg_name" "$arg_value" "$filter" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    }

    escape_sed_replacement() {
      printf '%s\n' "$1" | ${pkgs.gnused}/bin/sed 's/[&/\]/\\&/g'
    }

    # Patch a secret value into all agent config files.
    # Args: secret jq_arg_name opencode_filter [claude_filter] [gemini_filter] [toml_placeholder] [toml_append_section] [label] [forge_filter]
    patch_secret_to_all_configs() {
      local secret="$1" jq_arg="$2" opencode_filter="$3"
      local claude_filter="''${4:-}" gemini_filter="''${5:-}"
      local toml_placeholder="''${6:-}" toml_append="''${7:-}" label="''${8:-}"
      local forge_filter="''${9:-$claude_filter}"

      for OPENCODE_CFG in ${opencodeConfigPathList}; do
        if [[ -f "$OPENCODE_CFG" ]]; then
          patch_json_file "$OPENCODE_CFG" "$jq_arg" "$secret" "$opencode_filter"
          echo "✓ Patched $(basename "$(dirname "$OPENCODE_CFG")")/opencode.json with $label"
        fi
      done

      if [[ -n "$claude_filter" ]] && [[ -f "$HOME/.mcp.json" ]]; then
        patch_json_file "$HOME/.mcp.json" "$jq_arg" "$secret" "$claude_filter"
        echo "✓ Patched .mcp.json with $label"
      fi

      if [[ -n "$toml_placeholder" ]] && [[ -f "$HOME/.codex/config.toml" ]]; then
        local escaped
        escaped="$(escape_sed_replacement "$secret")"
        ${pkgs.gnused}/bin/sed -i "s/$toml_placeholder/$escaped/g" "$HOME/.codex/config.toml"
        if [[ -n "$toml_append" ]] && grep -q "$toml_append" "$HOME/.codex/config.toml"; then
          ${pkgs.gnused}/bin/sed -i "/$toml_append/a Z_AI_API_KEY = \"$escaped\"" "$HOME/.codex/config.toml"
        fi
        echo "✓ Patched codex config.toml with $label"
      fi

      if [[ -n "$gemini_filter" ]] && [[ -f "$HOME/.gemini/settings.json" ]]; then
        patch_json_file "$HOME/.gemini/settings.json" "$jq_arg" "$secret" "$gemini_filter"
        echo "✓ Patched gemini settings.json with $label"
      fi

      # Forge profile MCP configs (same JSON format as Claude .mcp.json).
      if [[ -n "$forge_filter" ]]; then
        for FORGE_MCP in ${forgeMcpPathList}; do
          if [[ -f "$FORGE_MCP" ]]; then
            patch_json_file "$FORGE_MCP" "$jq_arg" "$secret" "$forge_filter"
            echo "✓ Patched $(basename "$(dirname "$FORGE_MCP")")/.mcp.json with $label"
          fi
        done
      fi
    }

    # --- Z.AI ---
    if [[ -n "${cfg.secrets.zaiApiKeyFile or ""}" ]]; then
      if [[ -f "${cfg.secrets.zaiApiKeyFile}" ]]; then
        ZAI_KEY="$(cat "${cfg.secrets.zaiApiKeyFile}")"
        patch_secret_to_all_configs \
          "$ZAI_KEY" key \
          ${lib.escapeShellArg opencodeZaiFilter} \
          ${lib.escapeShellArg claudeZaiFilter} \
          ${lib.escapeShellArg geminiZaiFilter} \
          "__ZAI_API_KEY_PLACEHOLDER__" \
          '\[mcp_servers.zai-mcp-server.env\]' \
          "Z.AI API key + remote MCPs" \
          ${lib.escapeShellArg forgeZaiFilter}

        # Forge profiles using zai_coding provider need .credentials.json
        ${lib.concatStringsSep "\n" (
          map (profileName: ''
            FORGE_CRED="$HOME/.${profileName}/.credentials.json"
            if [[ -d "$HOME/.${profileName}" ]]; then
              printf '[{"id":"zai_coding","auth_details":{"api_key":"%s"}}]' "$ZAI_KEY" > "$FORGE_CRED"
              chmod 600 "$FORGE_CRED"
              echo "✓ Wrote ${profileName}/.credentials.json with Z.AI key"
            fi
          '') zaiProfileNames
        )}

        unset ZAI_KEY
      else
        echo "⚠ ${cfg.secrets.zaiApiKeyFile} not found - run 'just nixos' first"
      fi
    fi

    # --- OpenRouter ---
    if [[ -n "${cfg.secrets.openrouterApiKeyFile or ""}" ]]; then
      if [[ -f "${cfg.secrets.openrouterApiKeyFile}" ]]; then
        OPENROUTER_KEY="$(cat "${cfg.secrets.openrouterApiKeyFile}")"
        patch_secret_to_all_configs \
          "$OPENROUTER_KEY" key \
          ${lib.escapeShellArg openrouterPlaceholderFilter} \
          "" "" "" "" \
          "OpenRouter API key"
        unset OPENROUTER_KEY
      else
        echo "⚠ ${cfg.secrets.openrouterApiKeyFile} not found - run 'just nixos' first"
      fi
    fi

    # --- Context7 ---
    if [[ -n "${cfg.secrets.context7ApiKeyFile or ""}" ]]; then
      if [[ -f "${cfg.secrets.context7ApiKeyFile}" ]]; then
        CONTEXT7_KEY="$(cat "${cfg.secrets.context7ApiKeyFile}")"
        patch_secret_to_all_configs \
          "$CONTEXT7_KEY" key \
          ${lib.escapeShellArg context7PlaceholderFilter} \
          ${lib.escapeShellArg context7PlaceholderFilter} \
          ${lib.escapeShellArg context7PlaceholderFilter} \
          "__CONTEXT7_API_KEY_PLACEHOLDER__" \
          "" \
          "Context7 API key"
        unset CONTEXT7_KEY
      else
        echo "⚠ ${cfg.secrets.context7ApiKeyFile} not found - run 'just nixos' first"
      fi
    fi

    # --- GitHub (from gh CLI) ---
    if ${pkgs.gh}/bin/gh auth status &> /dev/null; then
      GH_TOKEN="$(${pkgs.gh}/bin/gh auth token)"
      patch_secret_to_all_configs \
        "$GH_TOKEN" token \
        ${lib.escapeShellArg githubPlaceholderFilter} \
        ${lib.escapeShellArg githubPlaceholderFilter} \
        ${lib.escapeShellArg githubPlaceholderFilter} \
        "__GITHUB_TOKEN_PLACEHOLDER__" \
        "" \
        "GitHub token from gh CLI"
      unset GH_TOKEN
    else
      echo "⚠ gh CLI not authenticated - GitHub MCP will not work (run 'gh auth login')"
    fi

    # --- Oh My Pi Profile Secret Patching ---
    # Oh My Pi models.yml contains placeholders for API keys that must be
    # resolved at activation time.
    if [[ -n "${lib.optionalString cfg.pi.enable "true"}" ]]; then
      # Patch OpenRouter API key into omp models.yml files
      if [[ -n "${
        cfg.secrets.openrouterApiKeyFile or ""
      }" ]] && [[ -f "${cfg.secrets.openrouterApiKeyFile}" ]]; then
        OPENROUTER_KEY="$(cat "${cfg.secrets.openrouterApiKeyFile}")"
        for OMP_MODELS in ${piModelsPathList}; do
          if [[ -f "$OMP_MODELS" ]]; then
            ${pkgs.gnused}/bin/sed -i "s|__OPENROUTER_API_KEY_PLACEHOLDER__|$OPENROUTER_KEY|g" "$OMP_MODELS"
            echo "✓ Patched $(dirname "$OMP_MODELS" | xargs basename)/models.yml with OpenRouter key"
          fi
        done
        unset OPENROUTER_KEY
      fi

      # Patch MiniMax API key into omp models.yml files
      if [[ -n "${
        cfg.secrets.minimaxApiKeyFile or ""
      }" ]] && [[ -f "${cfg.secrets.minimaxApiKeyFile}" ]]; then
        MINIMAX_KEY="$(cat "${cfg.secrets.minimaxApiKeyFile}")"
        for OMP_MODELS in ${piModelsPathList}; do
          if [[ -f "$OMP_MODELS" ]]; then
            ${pkgs.gnused}/bin/sed -i "s|__MINIMAX_API_KEY_PLACEHOLDER__|$MINIMAX_KEY|g" "$OMP_MODELS"
            echo "✓ Patched $(dirname "$OMP_MODELS" | xargs basename)/models.yml with MiniMax key"
          fi
        done
        unset MINIMAX_KEY
      fi
    fi

  ''
