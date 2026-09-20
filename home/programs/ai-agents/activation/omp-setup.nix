# omp config.yml sync — yq-merge of managed keys into omp's app-owned YAML.
#
# omp owns ~/.omp/agent/config.yml (YAML, sparse writes), so it cannot be a
# home.file declaration (a store symlink would suppress the app's writes).
# This activation step instead yq-merges the managed key
# mcp.enableProjectConfig = false, which blocks project-level MCP sources so
# the managed ~/.omp/agent/mcp.json stays the single source of truth, while
# preserving app/user settings.
#
# Deferral semantics mirror herdr-setup.nix: only merge when config.yml
# already exists. While it is absent omp has not started yet; the app creates
# it on first launch and the next activation applies the merge.

{
  cfg,
  pkgs,
  lib,
}:
lib.mkIf cfg.omp.enable (
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    omp_cfg="$HOME/.omp/agent/config.yml"
    if [[ -f "$omp_cfg" ]]; then
      omp_tmp="$(mktemp)"
      if ${pkgs.yq}/bin/yq -y '.mcp.enableProjectConfig = false' "$omp_cfg" > "$omp_tmp" 2>/dev/null; then
        mv "$omp_tmp" "$omp_cfg"
        echo "✓ omp config.yml synced (mcp.enableProjectConfig = false)"
      else
        rm -f "$omp_tmp"
        echo "⚠ omp config.yml sync failed — leaving $omp_cfg untouched"
      fi
    fi
  ''
)
