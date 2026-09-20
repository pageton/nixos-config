# Antigravity CLI (agy) configuration activation.
#
# agy owns ~/.gemini/antigravity-cli/settings.json (sparse persistence) and
# ~/.gemini/config/mcp_config.json. Both are jq-merged here so app/user-owned
# keys survive while managed keys win. The legacy Gemini CLI layout
# (~/.gemini/settings.json) is no longer read by agy and is removed when it
# still carries the Home-Manager signature.

{
  cfg,
  pkgs,
  lib,
  toJSON,
  antigravitySettings,
  antigravityMcpServers,
}:
lib.mkIf cfg.antigravity.enable (
  let
    jq = "${pkgs.jq}/bin/jq";
    settingsFile = pkgs.writeText "antigravity-settings.json" (toJSON antigravitySettings);
    mcpFile = pkgs.writeText "antigravity-mcp.json" (toJSON {
      mcpServers = antigravityMcpServers;
    });

    mergeJsonFile = target: source: filter: ''
      if [[ -s "${target}" ]] && [[ ! -L "${target}" ]]; then
        ${jq} -s '${filter}' "${target}" "${source}" > "${target}.tmp"
        mv "${target}.tmp" "${target}"
      else
        rm -f "${target}"
        cp "${source}" "${target}"
        chmod 644 "${target}"
      fi
    '';
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.gemini/antigravity-cli" "$HOME/.gemini/config"

    legacy_settings="$HOME/.gemini/settings.json"
    if [[ -f "$legacy_settings" ]] && [[ ! -L "$legacy_settings" ]] && ${jq} -e '
      (.policyPaths // []) == ["$HOME/.gemini/policies"]
    ' "$legacy_settings" >/dev/null 2>&1; then
      rm -f "$legacy_settings"
      echo "✓ Removed legacy Antigravity settings.json (Gemini layout)"
    fi

    ${mergeJsonFile "$HOME/.gemini/antigravity-cli/settings.json" settingsFile "(.[0] // {}) * .[1]"}
    echo "✓ Antigravity settings configured"

    ${mergeJsonFile "$HOME/.gemini/config/mcp_config.json" mcpFile
      "(.[0] // {}) as $cur | (.[1].mcpServers // {}) as $new | $cur * { mcpServers: (($cur.mcpServers // {}) * $new) }"
    }
    echo "✓ Antigravity mcp_config.json configured"
  ''
)
