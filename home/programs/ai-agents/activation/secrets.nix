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
  antigravityZaiFilter,
  githubPlaceholderFilter,
  openrouterPlaceholderFilter,
  context7PlaceholderFilter,
}:
let
  zaiApiRoot = constants.services.zai.apiRoot;
in
lib.hm.dag.entryAfter [ "writeBoundary" "linkGeneration" "setupCodexConfig" "setupClaudeConfig" ] ''
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
  # Args: secret jq_arg_name opencode_filter [claude_filter] [antigravity_filter] [toml_placeholder] [toml_append_section] [label]
  patch_secret_to_all_configs() {
    local secret="$1" jq_arg="$2" opencode_filter="$3"
    local claude_filter="''${4:-}" antigravity_filter="''${5:-}"
    local toml_placeholder="''${6:-}" toml_append="''${7:-}" label="''${8:-}"

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

    if ${lib.boolToString cfg.antigravity.enable} && [[ -n "$antigravity_filter" ]] && [[ -f "$HOME/.gemini/settings.json" ]]; then
      patch_json_file "$HOME/.gemini/settings.json" "$jq_arg" "$secret" "$antigravity_filter"
      echo "✓ Patched antigravity settings.json with $label"
    fi

    # omp (~/.omp/agent/mcp.json) shares the Claude .mcp.json schema (.mcpServers),
    # so the same claude_filter injects/patches secrets there.
    if ${lib.boolToString cfg.omp.enable} && [[ -n "$claude_filter" ]] && [[ -f "$HOME/.omp/agent/mcp.json" ]]; then
      patch_json_file "$HOME/.omp/agent/mcp.json" "$jq_arg" "$secret" "$claude_filter"
      echo "✓ Patched omp mcp.json with $label"
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
        ${lib.escapeShellArg antigravityZaiFilter} \
        "__ZAI_API_KEY_PLACEHOLDER__" \
        '\[mcp_servers.zai-mcp-server.env\]' \
        "Z.AI API key + remote MCPs"

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

  # --- DeepSeek ---
  if [[ -n "${cfg.secrets.deepseekApiKeyFile or ""}" ]]; then
    if [[ -f "${cfg.secrets.deepseekApiKeyFile}" ]]; then
      DEEPSEEK_KEY="$(cat "${cfg.secrets.deepseekApiKeyFile}")"
      escaped_deepseek="$(escape_sed_replacement "$DEEPSEEK_KEY")"

      # OpenCode configs (providers.deepseek.options.apiKey)
      for OPENCODE_CFG in ${opencodeConfigPathList}; do
        if [[ -f "$OPENCODE_CFG" ]]; then
          ${pkgs.gnused}/bin/sed -i "s/__DEEPSEEK_API_KEY_PLACEHOLDER__/$escaped_deepseek/g" "$OPENCODE_CFG"
          echo "✓ Patched $(basename "$(dirname "$OPENCODE_CFG")")/opencode.json with DeepSeek key"
        fi
      done

      unset DEEPSEEK_KEY escaped_deepseek
    else
      echo "⚠ ${cfg.secrets.deepseekApiKeyFile} not found - run 'just nixos' first"
    fi
  fi

  # --- Xiaomi MiMo ---
  if [[ -n "${cfg.secrets.mimoApiKeyFile or ""}" ]]; then
    if [[ -f "${cfg.secrets.mimoApiKeyFile}" ]]; then
      MIMO_KEY="$(cat "${cfg.secrets.mimoApiKeyFile}")"
      escaped_mimo="$(escape_sed_replacement "$MIMO_KEY")"

      # OpenCode configs (providers.xiaomi-token-plan-sgp.options.apiKey)
      for OPENCODE_CFG in ${opencodeConfigPathList}; do
        if [[ -f "$OPENCODE_CFG" ]] && grep -q '__MIMO_API_KEY_PLACEHOLDER__' "$OPENCODE_CFG"; then
          ${pkgs.gnused}/bin/sed -i "s/__MIMO_API_KEY_PLACEHOLDER__/$escaped_mimo/g" "$OPENCODE_CFG"
          echo "✓ Patched $(basename "$(dirname "$OPENCODE_CFG")")/opencode.json with MiMo key"
        fi
      done

      unset MIMO_KEY escaped_mimo
    else
      echo "⚠ ${cfg.secrets.mimoApiKeyFile} not found - run 'just nixos' first"
    fi
  fi

''
