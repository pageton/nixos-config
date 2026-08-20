# ZCode provider sync — merges managed providers into ZCode's app-owned config.
#
# ~/.zcode/v2/config.json is rewritten by the running ZCode app, so it cannot be
# a home.file declaration. This activation step instead performs an idempotent
# jq merge over the provider registry in helpers/_zcode-providers.nix: entries
# are matched by baseURL substring and merged into place (models optionally
# deep-merged so UI-added models survive). API keys come from sops with a
# fallback to whatever the app already stored.
# Restart ZCode after activation — the app holds providers in memory and would
# otherwise overwrite this file on its next in-app settings change.

{
  cfg,
  pkgs,
  lib,
}:
lib.mkIf cfg.zcode.enable (
  let
    providers = import ../helpers/_zcode-providers.nix;

    jq = "${pkgs.jq}/bin/jq";

    # Expand a registry model entry into ZCode's provider.models shape.
    mkModel =
      m:
      {
        limit = {
          context = m.context;
          output = m.output;
        };
        modalities = {
          input = m.input;
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
          defaultVariant = m.reasoningDefault or "off";
        };
      };

    # match: baseURL substring identifying the provider entry to merge into.
    # mergeModels: deep-merge our models with existing ones (true) or replace (false).
    # keyFile: sops-decrypted key path; falls back to the app-stored key.
    managedProviders = [
      {
        match = "opencode.ai/zen";
        fallbackKey = "opencode-zen"; # entry name for a fresh config (existing entries are matched by baseURL)
        mergeModels = false;
        keyFile = cfg.secrets.opencodeZenApiKeyFile or "/run/secrets/opencode_zen_api_key";
        inherit (providers.opencodeZen) name kind baseURL;
        models = lib.mapAttrs (_: mkModel) providers.opencodeZen.models;
      }
      {
        match = "openrouter.ai";
        fallbackKey = "openrouter";
        mergeModels = true;
        keyFile = cfg.secrets.openrouterApiKeyFile or "/run/secrets/openrouter_api_key";
        inherit (providers.openrouter) name kind baseURL;
        models = lib.mapAttrs (_: mkModel) providers.openrouter.models;
      }
      {
        match = "api.deepseek.com";
        fallbackKey = "deepseek";
        mergeModels = true;
        keyFile = cfg.secrets.deepseekApiKeyFile or "/run/secrets/deepseek_api_key";
        inherit (providers.deepseek) name kind baseURL;
        models = lib.mapAttrs (_: mkModel) providers.deepseek.models;
      }
    ];

    providersJson = builtins.toJSON (
      map (p: {
        inherit (p)
          match
          fallbackKey
          mergeModels
          name
          kind
          baseURL
          models
          ;
      }) managedProviders
    );
    # Order matches providersJson entries.
    keyFilesList = lib.concatMapStringsSep " " (p: lib.escapeShellArg p.keyFile) managedProviders;
  in
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    zcode_cfg="$HOME/.zcode/v2/config.json"
    mkdir -p "$HOME/.zcode/v2"
    if [[ ! -f "$zcode_cfg" ]]; then
      printf '{"provider":{}}' > "$zcode_cfg"
    fi

    # Read sops keys (empty string when the secret file is absent yet).
    key_files=(${keyFilesList})
    keys_json="["
    keys_sep=""
    for f in "''${key_files[@]}"; do
      k=""
      if [[ -f "$f" ]]; then
        k="$(tr -d '[:space:]' < "$f")"
      fi
      keys_json="$keys_json$keys_sep$(${jq} -Rn --arg v "$k" '$v')"
      keys_sep=","
    done
    keys_json="$keys_json]"

    if ${jq} \
      --argjson prov '${providersJson}' \
      --argjson keys "$keys_json" '
      .provider = (.provider // {}) |
      reduce range(0; ($prov | length)) as $i (.;
        ($prov[$i]) as $p |
        ([.provider | to_entries[] | select((.value.options.baseURL // "") | contains($p.match)) | .key][0] // $p.fallbackKey) as $k |
        # jq "*" deep-merges nested objects, so models is assigned separately
        # below to honor mergeModels=false (replace) semantics.
        .provider[$k] = ((.provider[$k] // {}) * {
          name: $p.name,
          kind: $p.kind,
          source: "custom",
          options: {
            baseURL: $p.baseURL,
            apiKey: (if ($keys[$i] // "") != "" then $keys[$i] else (.provider[$k].options.apiKey? // "") end)
          }
        }) |
        .provider[$k].models = (if $p.mergeModels then ((.provider[$k].models? // {}) * $p.models) else $p.models end)
      )
    ' "$zcode_cfg" > "$zcode_cfg.tmp" && mv "$zcode_cfg.tmp" "$zcode_cfg"; then
      chmod 600 "$zcode_cfg"
      echo "✓ ZCode providers synced (OpenCode Zen + OpenRouter free + DeepSeek) — restart ZCode to load"
    else
      rm -f "$zcode_cfg.tmp"
      echo "⚠ ZCode provider sync failed — leaving $zcode_cfg untouched"
    fi
  ''
)
