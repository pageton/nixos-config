{
  aiPackages,
  config,
  lib,
  pkgs,
  setup,
  ...
}:

let
  extensions = import ./extension-resources.nix { inherit pkgs setup; };
  defaults = pkgs.writeText "pi-defaults.json" (
    builtins.toJSON {
      # Local preference (upstream yzua pins "gpt-6.1-sol" on a custom
      # openai-responses provider): this workstation authenticates against
      # the zai provider, so the default model stays glm-5.3. Max reasoning
      # is pinned per-model; defaultThinkingLevel stays the generic fallback.
      defaultModel = "glm-5.3";
      defaultThinkingLevel = "high";
      modelThinkingLevels = {
        "zai/glm-5.3" = "max";
      };
      extensions = [ "-builtin:mcp" ];
    }
  );
  agentDir = "${config.home.homeDirectory}/.pi/agent";
  stateDir = "${config.xdg.stateHome}/pi-config";
in
{
  # Herdr cold restore calls `pi --session PATH`, not the original launcher.
  # Keep RE root sessions on pi-re without changing the pinned Pi executable.
  home.packages = [
    (lib.hiPrio (
      pkgs.writeShellScriptBin "pi" ''
        exec ${pkgs.python3}/bin/python3 ${./resume-dispatch.py} ${lib.getExe aiPackages.pi} -- "$@"
      ''
    ))
  ];

  home = {
    file = {
      ".pi/agent/AGENTS.md".source = ./AGENTS.md;
      ".pi/agent/prompts".source = ./prompts;
      ".pi/agent/agents".source = ./agents;
      ".pi/agent/extensions/ask-user-question.ts".source =
        "${extensions}/lib/pi-config/ask-user-question.ts";
      ".pi/agent/extensions/agy-bridge.ts".source = "${extensions}/lib/pi-config/agy-bridge.ts";
      ".pi/agent/extensions/network-diagnostics.ts".source =
        "${extensions}/lib/pi-config/network-diagnostics.ts";
      ".pi/agent/extensions/upstream-retry.ts".source =
        "${extensions}/lib/pi-config/upstream-retry.ts";
      ".pi/agent/extensions/prompt-snippets".source = "${extensions}/lib/pi-config/prompt-snippets";
      ".pi/agent/extensions/web-fetch".source = "${extensions}/lib/pi-config/web-fetch";
      ".pi/agent/extensions/web-search".source = "${extensions}/lib/pi-config/web-search";
      ".pi/agent/extensions/interactive-subagents".source =
        "${extensions}/lib/pi-config/interactive-subagents";
    };

    # The first activation applies agreed defaults. Later UI changes remain user-owned.
    activation.initializePi = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      if [ -v DRY_RUN ]; then
        echo "Would initialize writable Pi settings and models"
      else
        ${pkgs.python3}/bin/python3 ${./initialize.py} \
          --agent-dir ${lib.escapeShellArg agentDir} \
          --state-dir ${lib.escapeShellArg stateDir} \
          --defaults ${defaults}
      fi
    '';
  };
}
