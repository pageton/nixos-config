# Forge configuration activation — generates per-profile .forge.toml and .mcp.json files
# as real files (not symlinks) so forge can modify them at runtime.
# Also creates directories and writes AGENTS.md + agent definitions.

{
  cfg,
  pkgs,
  lib,
  config,
}:
let
  forgeProfiles = import ../helpers/_forge-profiles.nix { inherit config; };
in
lib.mkIf cfg.forge.enable (
  let
    inherit (builtins) toJSON;
    settingsBuilders = import ../helpers/_settings-builders.nix { inherit cfg config lib; };
    inherit (settingsBuilders) forgeTomlByProfile forgeMcpJson;

    jq = "${pkgs.jq}/bin/jq";
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${lib.concatStringsSep "\n" (
      map (profile: ''
                mkdir -p "$HOME/.${profile.name}"
                mkdir -p "$HOME/.${profile.name}/agents"

                # Write .forge.toml (always overwrite — Nix is the source of truth)
                rm -f "$HOME/.${profile.name}/.forge.toml"
                cat > "$HOME/.${profile.name}/.forge.toml" << 'FORGE_TOML_EOF'
        ${forgeTomlByProfile.${profile.name}}
        FORGE_TOML_EOF
                echo "✓ Forge ${profile.name} .forge.toml configured"

                # Write .mcp.json — merge with existing if present (preserving user additions)
                FORGE_MCP_SRC=$(mktemp)
                cat > "$FORGE_MCP_SRC" << 'FORGE_MCP_JSON_EOF'
        ${toJSON forgeMcpJson}
        FORGE_MCP_JSON_EOF
                FORGE_MCP_TARGET="$HOME/.${profile.name}/.mcp.json"
                if [[ -f "$FORGE_MCP_TARGET" ]] && [[ ! -L "$FORGE_MCP_TARGET" ]]; then
                  ${jq} -s '(.[1].mcpServers) as $mcpServers | .[0] * .[1] | .mcpServers = $mcpServers' "$FORGE_MCP_TARGET" "$FORGE_MCP_SRC" > "$FORGE_MCP_TARGET.tmp"
                  mv "$FORGE_MCP_TARGET.tmp" "$FORGE_MCP_TARGET"
                else
                  rm -f "$FORGE_MCP_TARGET"
                  cp "$FORGE_MCP_SRC" "$FORGE_MCP_TARGET"
                  chmod 644 "$FORGE_MCP_TARGET"
                fi
                rm -f "$FORGE_MCP_SRC"
                echo "✓ Forge ${profile.name} .mcp.json configured"
      '') forgeProfiles.profiles
    )}
  ''
)
