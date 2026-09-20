# ZCode config sync — merges managed providers + settings into ZCode's
# app-owned files.
#
# ~/.zcode/v2/config.json (providers/models) and ~/.zcode/v2/setting.json
# (settings) are both rewritten by the running ZCode app, so neither can be a
# home.file declaration. This activation step instead performs idempotent jq
# merges over the registries in cfg.zcode.providers (helpers/_zcode-providers.nix
# by default) and cfg.zcode.extraSettings:
#   - providers are matched by baseURL substring and merged into place
#     (models optionally deep-merged so UI-added models survive);
#   - settings are deep-merged with managed keys winning and app keys
#     (recentProjects, window state, device pairing, ...) surviving.
# API keys come from sops with a fallback to whatever the app already stored.
# Restart ZCode after activation — the app holds providers in memory and would
# otherwise overwrite these files on its next in-app settings change.

{
  cfg,
  pkgs,
  lib,
}:
lib.mkIf cfg.zcode.enable (
  let
    jq = "${pkgs.jq}/bin/jq";

    # Expand a registry model entry into ZCode's provider.models shape.
    mkModel =
      m:
      {
        limit = { inherit (m) context output; };
        modalities = {
          inherit (m) input;
          output = [ "text" ];
        };
        zcode.modified = true;
      }
      // lib.optionalAttrs m.reasoning {
        reasoning = {
          enabled = true;
          variants = [
            "off"
            "high"
            "max"
          ];
          defaultVariant = m.reasoningDefault;
        };
      };

    # Resolve the sops key file for one provider: explicit keyFile wins,
    # then the programs.aiAgents.secrets option named by `secret`, then "".
    mkKeyFile =
      p:
      if p.keyFile != null then
        p.keyFile
      else if
        p.secret != null && builtins.hasAttr p.secret cfg.secrets && cfg.secrets.${p.secret} != null
      then
        cfg.secrets.${p.secret}
      else
        "";

    managedProviders = lib.mapAttrsToList (_: p: {
      inherit (p)
        match
        fallbackKey
        mergeModels
        name
        kind
        baseURL
        ;
      keyFile = mkKeyFile p;
      models = lib.mapAttrs (_: mkModel) p.models;
    }) cfg.zcode.providers;

    providersJson = builtins.toJSON managedProviders;
    settingsJson = builtins.toJSON cfg.zcode.extraSettings;

    # Key file paths in the same order as providersJson entries; bash reads
    # each file's content into a parallel JSON array.
    keyFilesList = lib.concatMapStringsSep " " (p: lib.escapeShellArg (mkKeyFile p)) managedProviders;

    # Array-safe recursive merge: objects merge key-by-key, everything else
    # (arrays, scalars) is replaced wholesale by the managed value. jq's "*"
    # is not usable here — it errors when two arrays have different lengths.
    deepmergeDef = ''
      def deepmerge($base; $m):
        if ($base | type) == "object" and ($m | type) == "object" then
          reduce ($m | keys[]) as $k ($base;
            .[$k] = deepmerge(.[$k] // {}; $m[$k]))
        else $m end;
    '';

    settingsBlock =
      if cfg.zcode.extraSettings != { } then
        ''
          zcode_settings="$HOME/.zcode/v2/setting.json"
          if [[ -f "$zcode_settings" ]]; then
            if ${jq} --argjson managed '${settingsJson}' '
              ${deepmergeDef}
              deepmerge(.; $managed)
            ' "$zcode_settings" > "$zcode_settings.tmp" && mv "$zcode_settings.tmp" "$zcode_settings"; then
              chmod 600 "$zcode_settings"
              echo "✓ ZCode settings synced (managed keys win, app keys survive)"
            else
              rm -f "$zcode_settings.tmp"
              echo "⚠ ZCode settings sync failed — leaving $zcode_settings untouched"
            fi
          fi
        ''
      else
        "";
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    zcode_cfg="$HOME/.zcode/v2/config.json"
    mkdir -p "$HOME/.zcode/v2"
    if [[ ! -f "$zcode_cfg" ]]; then
      printf '{"provider":{}}' > "$zcode_cfg"
    fi

    # Read sops keys (empty string when a path is blank or the file is absent).
    key_files=(${keyFilesList})
    keys_json="["
    keys_sep=""
    for f in "''${key_files[@]}"; do
      k=""
      if [[ -n "$f" && -f "$f" ]]; then
        k="$(tr -d '[:space:]' < "$f")"
      fi
      keys_json="$keys_json$keys_sep$(${jq} -Rn --arg v "$k" '$v')"
      keys_sep=","
    done
    keys_json="$keys_json]"

    if ${jq} \
      --argjson prov '${providersJson}' \
      --argjson keys "$keys_json" '
      ${deepmergeDef}
      .provider = (.provider // {}) |
      reduce range(0; ($prov | length)) as $i (.;
        ($prov[$i]) as $p |
        ([.provider | to_entries[] | select((.value.options.baseURL // "") | contains($p.match)) | .key][0] // $p.fallbackKey) as $k |
        .provider[$k] = ((.provider[$k] // {}) * {
          name: $p.name,
          kind: $p.kind,
          source: "custom",
          options: {
            baseURL: $p.baseURL,
            apiKey: (if ($keys[$i] // "") != "" then $keys[$i] else (.provider[$k].options.apiKey? // "") end)
          }
        }) |
        .provider[$k].models = (if $p.mergeModels then deepmerge((.provider[$k].models? // {}); $p.models) else $p.models end)
      )
    ' "$zcode_cfg" > "$zcode_cfg.tmp" && mv "$zcode_cfg.tmp" "$zcode_cfg"; then
      chmod 600 "$zcode_cfg"
      echo "✓ ZCode providers synced — restart ZCode to load"
    else
      rm -f "$zcode_cfg.tmp"
      echo "⚠ ZCode provider sync failed — leaving $zcode_cfg untouched"
    fi

    ${settingsBlock}
  ''
)
