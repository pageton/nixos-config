# dsh profile patch sync — managed MCP entries in each dsh profile's
# cordis.patch.yml.
#
# dsh composes a profile as: bundle layers → <profile>/cordis.patch.yml →
# --patch overlays. The user owns cordis.patch.yml, so it cannot be a
# home.file declaration (a store symlink would clobber user edits on every
# switch). This activation step instead yq-merges the shared MCP servers as
# cordis entries mounting @deepseek-ai/dsh-mcp-client, replacing any
# previously managed entries (id prefix `dsh-managed-mcp-`) in place while
# preserving user entries. Only profiles that already exist are touched: dsh
# auto-initializes new profiles on first boot and the next activation applies
# the merge (same deferral semantics as omp-setup.nix).
#
# Secret material never enters the store: entries are generated with
# placeholders ({env:ZAI_API_KEY} header refs, __*_PLACEHOLDER__ tokens), then
# substituted in place from /run/secrets and the gh CLI after the merge.

{
  cfg,
  pkgs,
  lib,
  ...
}:

let
  mcpTransforms = import ../helpers/_mcp-transforms.nix { inherit cfg lib; };
  inherit (mcpTransforms) dshManagedMcpPatch;

  # JSON is a YAML subset — yq consumes it directly.
  managedJson = pkgs.writeText "dsh-managed-mcp.json" (builtins.toJSON dshManagedMcpPatch);
in
lib.mkIf (cfg.enable && cfg.dsh.enable) (
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dsh_profiles="$HOME/.dsh/profiles"
    if [[ ! -d "$dsh_profiles" ]]; then
      echo "ℹ No dsh profiles yet — skipping MCP patch sync"
    else
      merged=0
      for patch_file in "$dsh_profiles"/*/cordis.patch.yml; do
        [[ -f "$patch_file" ]] || continue
        tmp="$(mktemp)"
        # pkgs.yq is kislyuk yq (jq semantics): `.` is the first file,
        # `input` reads the second. Strip previous managed content — the
        # current wrapper shape (marker `managed: true`) and the older flat
        # `dsh-managed-mcp-*` ids from the first iteration — then append the
        # fresh set.
        if ${pkgs.yq}/bin/yq -y \
          '[ .[] | select(((.managed // false) | not) and ((.id // "") | test("^dsh-managed-mcp-") | not)) ] + [ input[] ]' \
          "$patch_file" "${managedJson}" > "$tmp" 2>/dev/null; then
          mv "$tmp" "$patch_file"
          merged=$((merged + 1))
        else
          rm -f "$tmp"
          echo "⚠ dsh MCP patch sync failed for $patch_file — leaving untouched"
        fi
      done
      if [[ "$merged" -gt 0 ]]; then
        echo "✓ Synced dsh managed MCP entries into $merged profile patch file(s)"
      fi

    # Default permission mode (DSH_PERMISSION_MODE=danger-full-access: no
    # sandbox, no approval prompts) is exported by the Nix dsh launcher in
    # services.nix — dsh's .env blocklist rejects that name here (fatal).

      # Resolve placeholders in the merged entries in place. Only the three
      # known managed markers are touched; anything else the user added via
      # {env:...} syntax passes through verbatim.
      for patch_file in "$dsh_profiles"/*/cordis.patch.yml; do
        [[ -f "$patch_file" ]] || continue
        grep -q '__CONTEXT7_API_KEY_PLACEHOLDER__\|{env:ZAI_API_KEY}\|__GITHUB_TOKEN_PLACEHOLDER__' "$patch_file" || continue
        if grep -q '{env:ZAI_API_KEY}' "$patch_file" && [[ -f "${cfg.secrets.zaiApiKeyFile}" ]]; then
          ZAI_KEY="$(tr -d '\r\n' < "${cfg.secrets.zaiApiKeyFile}")"
          ${pkgs.yq}/bin/yq -y --arg key "$ZAI_KEY" \
            'walk(if type == "string" then gsub("\\{env:ZAI_API_KEY\\}"; $key) else . end)' \
            "$patch_file" > "$patch_file.tmp" 2>/dev/null \
            && mv "$patch_file.tmp" "$patch_file" \
            && echo "✓ Patched dsh profile patch with Z.AI key"
        fi
        if grep -q '__CONTEXT7_API_KEY_PLACEHOLDER__' "$patch_file" && [[ -f "${cfg.secrets.context7ApiKeyFile}" ]]; then
          CTX_KEY="$(tr -d '\r\n' < "${cfg.secrets.context7ApiKeyFile}")"
          ${pkgs.yq}/bin/yq -y --arg key "$CTX_KEY" \
            'walk(if type == "string" then gsub("__CONTEXT7_API_KEY_PLACEHOLDER__"; $key) else . end)' \
            "$patch_file" > "$patch_file.tmp" 2>/dev/null \
            && mv "$patch_file.tmp" "$patch_file" \
            && echo "✓ Patched dsh profile patch with Context7 key"
        fi
        if grep -q '__GITHUB_TOKEN_PLACEHOLDER__' "$patch_file" && ${pkgs.gh}/bin/gh auth status &> /dev/null; then
          GH_TOKEN_VALUE="$(${pkgs.gh}/bin/gh auth token)"
          ${pkgs.yq}/bin/yq -y --arg key "$GH_TOKEN_VALUE" \
            'walk(if type == "string" then gsub("__GITHUB_TOKEN_PLACEHOLDER__"; $key) else . end)' \
            "$patch_file" > "$patch_file.tmp" 2>/dev/null \
            && mv "$patch_file.tmp" "$patch_file" \
            && echo "✓ Patched dsh profile patch with GitHub token"
        fi
      done
    fi
  ''
)
