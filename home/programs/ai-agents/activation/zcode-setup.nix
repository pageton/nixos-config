# ZCode activation — installs custom agents and merges managed hooks.

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
    agentFiles = lib.mapAttrs (
      name: content: pkgs.writeText "zcode-agent-${name}.md" content
    ) cfg.zcode.agents;
    agentInstallScript = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: source: ''
        agent_target="$agents_dir/${name}.md"
        agent_tmp="$agent_target.tmp"

        if [[ -f "$agent_target" ]] && [[ ! -L "$agent_target" ]] && ${cmp} -s "${source}" "$agent_target"; then
          :
        else
          rm -f "$agent_tmp"
          cp "${source}" "$agent_tmp"
          chmod 644 "$agent_tmp"
          mv "$agent_tmp" "$agent_target"
        fi
      '') agentFiles
    );
    agentCount = builtins.length (builtins.attrNames agentFiles);
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_dir="$HOME/.zcode/cli"
    target="$config_dir/config.json"
    mkdir -p "$config_dir"
    agents_dir="$HOME/.zcode/agents"
    mkdir -p "$agents_dir"

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

    ${agentInstallScript}

    echo "✓ ZCode hooks and ${toString agentCount} custom agents configured"
  ''
)
