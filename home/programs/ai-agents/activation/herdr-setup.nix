# herdr OpenCode V2 plugin registration — idempotent merge into cli.json.
#
# OpenCode V2 replaces the V1 TUI config files with cli.json, which the app
# owns: on first V2 start it migrates tui.json / kv.json into cli.json, and
# later TUI changes are persisted there. A home.file declaration would be a
# read-only store symlink — it would suppress that migration and break writes —
# so registration is a jq merge instead.
#
# Mirrors `herdr integration install opencode` deferral semantics: only merge
# when cli.json already exists. While it is absent OpenCode has not started V2
# yet, and `herdr integration status` treats the V1-only install as current.
# The entry matcher mirrors herdr's own plugin_entry_matches (plain string,
# {package = ...} object, or [spec, ...] tuple) so options-bearing entries are
# recognized instead of duplicated.

{
  cfg,
  pkgs,
  lib,
}:
lib.mkIf (cfg.herdr.enable && cfg.opencode.enable) (
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cli_cfg="$HOME/.config/opencode/cli.json"
    if [[ -f "$cli_cfg" ]]; then
      cli_tmp="$(mktemp)"
      if ${pkgs.jq}/bin/jq '
        def is_herdr:
          . == "./herdr-opencode"
          or ((type == "object") and (.package? == "./herdr-opencode"))
          or ((type == "array") and ((.[0]?) == "./herdr-opencode"));
        if (.plugins | type) == "array" then
          .plugins = (if any(.plugins[]; is_herdr) then .plugins else .plugins + ["./herdr-opencode"] end)
        elif .plugins == null then
          .plugins = ["./herdr-opencode"]
        else
          .
        end
      ' "$cli_cfg" > "$cli_tmp" 2>/dev/null; then
        mv "$cli_tmp" "$cli_cfg"
        echo "✓ herdr OpenCode V2 plugin registered in cli.json"
      else
        rm -f "$cli_tmp"
        echo "⚠ herdr OpenCode V2 registration skipped — cli.json is not plain JSON; add \"./herdr-opencode\" to its plugins array manually"
      fi
    fi
  ''
)
