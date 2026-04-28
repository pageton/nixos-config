# Zsh alias generation for AI agent launchers and workflow prompts.
#
# NOTE: Agent aliases are also defined in scripts/ai/_agent-registry.sh for runtime
# dispatch (launcher/iter). Adding or renaming an alias requires updating both files.

{
  config,
  constants,
  lib,
  pkgs,
  ...
}:

let
  scriptsDir = "${config.home.homeDirectory}/${constants.paths.scripts}";
  models = import ./_models.nix;
  workflowPrompts = import ./_workflow-prompts.nix { };
  commitSplitPrompt = workflowPrompts.commitSplit;
  refactorMaintainabilityPrompt = workflowPrompts.refactorMaintainability;
  securityAuditPrompt = workflowPrompts.securityAudit;
  bugfixRootCausePrompt = workflowPrompts.bugfixRootCause;
  dependencyUpgradePrompt = workflowPrompts.dependencyUpgrade;
  buildPerformancePrompt = workflowPrompts.buildPerformance;
  runtimePerformancePrompt = workflowPrompts.runtimePerformance;
  markdownSyncPrompt = workflowPrompts.markdownSync;

  codexBase = "command codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox";

  gptLowModel = models.gpt-low;
  gptMedModel = models.gpt-default;
  gptXHighModel = models.gpt-xhigh;

  mkAliasAttrs =
    aliasSpecs:
    builtins.listToAttrs (
      map (spec: {
        name = spec.alias;
        value = spec.command;
      }) aliasSpecs
    );

  aiAgentAliasSpecs = [
    {
      alias = "cl";
      command = "claude";
      workflowPromptMode = "positional";
    }
    {
      alias = "clu";
      command = "claude --dangerously-skip-permissions";
      workflowPromptMode = "positional";
    }
    {
      alias = "clglm";
      command = "claude_glm";
      workflowPromptMode = "positional";
    }
    {
      alias = "ocl";
      command = "claude --model opus";
      workflowPromptMode = "positional";
    }
    {
      alias = "hcl";
      command = "claude --model haiku";
      workflowPromptMode = "positional";
    }
    {
      alias = "gem";
      command = "gemini --approval-mode=yolo";
      workflowPromptMode = "positional";
    }
    {
      alias = "cx";
      command = codexBase;
      workflowPromptMode = "positional";
    }
    {
      alias = "lcx";
      command = "${codexBase} -c 'model_reasoning_effort=\"low\"'";
      workflowPromptMode = "positional";
    }
    {
      alias = "mcx";
      command = "${codexBase} -c 'model_reasoning_effort=\"medium\"'";
      workflowPromptMode = "positional";
    }
    {
      alias = "hcx";
      command = "${codexBase} -c 'model_reasoning_effort=\"high\"'";
      workflowPromptMode = "positional";
    }
    {
      alias = "xcx";
      command = "${codexBase} -c 'model_reasoning_effort=\"xhigh\"'";
      workflowPromptMode = "positional";
    }
    {
      alias = "oc";
      command = "opencode";
      workflowPromptMode = "flag";
    }
    {
      alias = "ocglm";
      command = "opencode_glm";
      workflowPromptMode = "flag";
    }
    {
      alias = "ocgem";
      command = "opencode_gemini";
      workflowPromptMode = "flag";
    }
    {
      alias = "ocgpt";
      command = "opencode_gpt";
      workflowPromptMode = "flag";
    }
    {
      alias = "ocor";
      command = "opencode_openrouter";
      workflowPromptMode = "flag";
    }
    {
      alias = "locgpt";
      command = "opencode_gpt --model ${gptLowModel}";
      workflowPromptMode = "flag";
    }
    {
      alias = "mocgpt";
      command = "opencode_gpt --model ${gptMedModel}";
      workflowPromptMode = "flag";
    }
    {
      alias = "xocgpt";
      command = "opencode_gpt --model ${gptXHighModel}";
      workflowPromptMode = "flag";
    }
    {
      alias = "ocs";
      command = "opencode_sonnet";
      workflowPromptMode = "flag";
    }
    {
      alias = "oczen";
      command = "opencode_zen";
      workflowPromptMode = "flag";
    }
    {
      alias = "fg";
      command = "forge";
      workflowPromptMode = "flag";
    }
    {
      alias = "fgglm";
      command = "forge_glm";
      workflowPromptMode = "flag";
    }
    {
      alias = "fggem";
      command = "forge_gemini";
      workflowPromptMode = "flag";
    }
    {
      alias = "fggpt";
      command = "forge_gpt";
      workflowPromptMode = "flag";
    }
    {
      alias = "fgor";
      command = "forge_openrouter";
      workflowPromptMode = "flag";
    }
    {
      alias = "fgs";
      command = "forge_sonnet";
      workflowPromptMode = "flag";
    }
    {
      alias = "fgzen";
      command = "forge_zen";
      workflowPromptMode = "flag";
    }
    # Oh My Pi — omp prefix (explicit)
    {
      alias = "omp";
      command = "omp";
      workflowPromptMode = "flag";
    }
    {
      alias = "omps";
      command = "omp_sonnet";
      workflowPromptMode = "flag";
    }
    {
      alias = "ompop";
      command = "omp_opus";
      workflowPromptMode = "flag";
    }
    {
      alias = "ompglm";
      command = "omp_glm";
      workflowPromptMode = "flag";
    }
    {
      alias = "ompgem";
      command = "omp_gemini";
      workflowPromptMode = "flag";
    }
    {
      alias = "ompgpt";
      command = "omp_gpt";
      workflowPromptMode = "flag";
    }
    {
      alias = "ompor";
      command = "omp_openrouter";
      workflowPromptMode = "flag";
    }
    {
      alias = "ompzen";
      command = "omp_zen";
      workflowPromptMode = "flag";
    }
    # Oh My Pi — pi prefix (shorter)
    {
      alias = "pi";
      command = "omp";
      workflowPromptMode = "flag";
    }
    {
      alias = "pis";
      command = "omp_sonnet";
      workflowPromptMode = "flag";
    }
    {
      alias = "piop";
      command = "omp_opus";
      workflowPromptMode = "flag";
    }
    {
      alias = "piglm";
      command = "omp_glm";
      workflowPromptMode = "flag";
    }
    {
      alias = "pigem";
      command = "omp_gemini";
      workflowPromptMode = "flag";
    }
    {
      alias = "pigpt";
      command = "omp_gpt";
      workflowPromptMode = "flag";
    }
    {
      alias = "pior";
      command = "omp_openrouter";
      workflowPromptMode = "flag";
    }
    {
      alias = "pizen";
      command = "omp_zen";
      workflowPromptMode = "flag";
    }
  ];

  workflowPromptSpecs = [
    {
      suffix = "cm";
      prompt = commitSplitPrompt;
      envVar = "COMMIT_SPLIT_PROMPT";
    }
    {
      suffix = "rf";
      prompt = refactorMaintainabilityPrompt;
      envVar = "REFACTOR_MAINTAINABILITY_PROMPT";
    }
    {
      suffix = "fx";
      prompt = bugfixRootCausePrompt;
      envVar = "BUGFIX_ROOT_CAUSE_PROMPT";
    }
    {
      suffix = "sa";
      prompt = securityAuditPrompt;
      envVar = "SECURITY_AUDIT_PROMPT";
    }
    {
      suffix = "du";
      prompt = dependencyUpgradePrompt;
      envVar = "DEPENDENCY_UPGRADE_PROMPT";
    }
    {
      suffix = "bp";
      prompt = buildPerformancePrompt;
      envVar = "BUILD_PERFORMANCE_PROMPT";
    }
    {
      suffix = "rp";
      prompt = runtimePerformancePrompt;
      envVar = "RUNTIME_PERFORMANCE_PROMPT";
    }
    {
      suffix = "md";
      prompt = markdownSyncPrompt;
      envVar = "MARKDOWN_SYNC_PROMPT";
    }
  ];

  workflowAgentSpecs = builtins.filter (agent: agent ? workflowPromptMode) aiAgentAliasSpecs;

  aiWorkflowAliasSpecs = lib.flatten (
    map (
      workflow:
      map (agent: {
        alias = "${agent.alias}${workflow.suffix}";
        command =
          if agent.workflowPromptMode == "flag" then
            "_ai_agent_exec ${agent.alias}${workflow.suffix} -- ${agent.command} --prompt ${lib.escapeShellArg workflow.prompt}"
          else
            "_ai_agent_exec ${agent.alias}${workflow.suffix} -- ${agent.command} ${lib.escapeShellArg workflow.prompt}";
      }) workflowAgentSpecs
    ) workflowPromptSpecs
  );

  workflowClipboardAliasSpecs = map (workflow: {
    alias = "cp${workflow.suffix}";
    command =
      "if command -v wl-copy >/dev/null 2>&1; then printf '%s' ${lib.escapeShellArg workflow.prompt} | wl-copy; "
      + "elif command -v xclip >/dev/null 2>&1; then printf '%s' ${lib.escapeShellArg workflow.prompt} | xclip -selection clipboard; "
      + "else echo 'Clipboard tool not found (need wl-copy or xclip)' >&2; false; fi "
      + "&& echo 'Copied ${workflow.suffix} prompt to clipboard'";
  }) workflowPromptSpecs;

  aiAliases = mkAliasAttrs (
    (map (
      spec: spec // { command = "_ai_agent_exec ${spec.alias} -- ${spec.command}"; }
    ) aiAgentAliasSpecs)
    ++ aiWorkflowAliasSpecs
    ++ workflowClipboardAliasSpecs
  );

  # Shared env var passthrough for workflow prompts (used by launcher and iter wrappers).
  mkWorkflowEnvVars =
    targetScript:
    let
      envAssignments = map (spec: "${spec.envVar}=${lib.escapeShellArg spec.prompt}") workflowPromptSpecs;
    in
    ''
      ${builtins.concatStringsSep " \\\n    " envAssignments} \
      exec ${targetScript} "$@"
    '';

  aiAgentLauncher = pkgs.writeShellScriptBin "ai-agent-launcher" (
    mkWorkflowEnvVars "${scriptsDir}/ai/agent-launcher.sh"
  );
in
{
  inherit
    aiAliases
    aiAgentLauncher
    workflowPrompts
    mkWorkflowEnvVars
    ;
  aiAgentInventory = pkgs.writeShellScriptBin "ai-agent-inventory" ''
    exec ${scriptsDir}/ai/agent-inventory.sh "$@"
  '';
}
