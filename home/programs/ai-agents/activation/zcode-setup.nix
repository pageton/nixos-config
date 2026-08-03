# ZCode configuration activation — merges managed hooks into ~/.zcode/cli/config.json.

{
  cfg,
  pkgs,
  lib,
  toJSON,
}:
lib.mkIf cfg.zcode.enable (
  let
    jq = "${pkgs.jq}/bin/jq";
    cmp = "${pkgs.diffutils}/bin/cmp";
    zcodeConfigFile = pkgs.writeText "zcode-config.json" (toJSON {
      hooks = {
        enabled = true;
        timeoutMs = 60000;
        maxOutputBytes = 32768;
        events = cfg.zcode.hooks;
      };
    });
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_dir="$HOME/.zcode/cli"
    target="$config_dir/config.json"
    mkdir -p "$config_dir"

    if [[ -f "$target" ]] && [[ ! -L "$target" ]]; then
      ${jq} -s '(.[1].hooks) as $hooks | .[0] * .[1] | .hooks = $hooks' \
        "$target" "${zcodeConfigFile}" > "$target.tmp"
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

    echo "✓ ZCode hooks configured"
  ''
)
