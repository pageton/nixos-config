# Single source of truth for all agent aliases and workflow specs.
# Generates both Nix zsh aliases and a bash registry fragment
# sourced by scripts/ai/_agent-registry.sh at runtime.

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

  flattenForAlias = builtins.replaceStrings [ "\n" ] [ "\\n" ];

  codexBase = "command codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox";
  codexHeadless = "codex exec --dangerously-bypass-approvals-and-sandbox";

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

  # Single source of truth for all agent aliases.
  # Fields used by Nix zsh alias generation: alias, command, workflowPromptMode
  # Fields used by bash registry generation: envMarker, interactiveCommand, headlessCommand, tool, launcherSimple
  aiAgentAliasSpecs = [
    # Claude Code
    {
      alias = "cl";
      command = "claude";
      workflowPromptMode = "positional";
      envMarker = "-";
      interactiveCommand = "claude --dangerously-skip-permissions";
      headlessCommand = "claude --print";
      tool = "claude";
      launcherSimple = true;
    }
    {
      alias = "clu";
      command = "claude --dangerously-skip-permissions";
      workflowPromptMode = "positional";
      envMarker = "-";
      interactiveCommand = "claude --dangerously-skip-permissions";
      headlessCommand = "claude --dangerously-skip-permissions --print";
      tool = "claude";
      launcherSimple = false;
    }
    {
      alias = "clglm";
      command = "claude_glm";
      workflowPromptMode = "positional";
      envMarker = "ZAI";
      interactiveCommand = "claude --dangerously-skip-permissions";
      headlessCommand = "claude --dangerously-skip-permissions --print";
      tool = "claude";
      launcherSimple = true;
    }
    {
      alias = "clsk";
      command = "claude_seek";
      workflowPromptMode = "positional";
      envMarker = "DEEPSEEK";
      interactiveCommand = "claude --dangerously-skip-permissions";
      headlessCommand = "claude --dangerously-skip-permissions --print";
      tool = "claude";
      launcherSimple = true;
    }
    {
      alias = "ocl";
      command = "claude --model opus";
      workflowPromptMode = "positional";
      envMarker = "-";
      interactiveCommand = "claude --dangerously-skip-permissions --model opus";
      headlessCommand = "claude --model opus --print";
      tool = "claude";
      launcherSimple = true;
    }
    {
      alias = "hcl";
      command = "claude --model haiku";
      workflowPromptMode = "positional";
      envMarker = "-";
      interactiveCommand = "claude --dangerously-skip-permissions --model haiku";
      headlessCommand = "claude --model haiku --print";
      tool = "claude";
      launcherSimple = true;
    }

    # Codex
    {
      alias = "cx";
      command = codexBase;
      workflowPromptMode = "positional";
      envMarker = "-";
      interactiveCommand = "codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox";
      headlessCommand = codexHeadless;
      tool = "codex";
      launcherSimple = true;
    }
    {
      alias = "lcx";
      command = "${codexBase} -c 'model_reasoning_effort=\"low\"'";
      workflowPromptMode = "positional";
      envMarker = "-";
      interactiveCommand = ''codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="low"' '';
      headlessCommand = "${codexHeadless} -c 'model_reasoning_effort=\"low\"'";
      tool = "codex";
      launcherSimple = true;
    }
    {
      alias = "mcx";
      command = "${codexBase} -c 'model_reasoning_effort=\"medium\"'";
      workflowPromptMode = "positional";
      envMarker = "-";
      interactiveCommand = ''codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="medium"' '';
      headlessCommand = "${codexHeadless} -c 'model_reasoning_effort=\"medium\"'";
      tool = "codex";
      launcherSimple = true;
    }
    {
      alias = "hcx";
      command = "${codexBase} -c 'model_reasoning_effort=\"high\"'";
      workflowPromptMode = "positional";
      envMarker = "-";
      interactiveCommand = ''codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="high"' '';
      headlessCommand = "${codexHeadless} -c 'model_reasoning_effort=\"high\"'";
      tool = "codex";
      launcherSimple = true;
    }
    {
      alias = "xcx";
      command = "${codexBase} -c 'model_reasoning_effort=\"xhigh\"'";
      workflowPromptMode = "positional";
      envMarker = "-";
      interactiveCommand = ''codex --no-alt-screen --dangerously-bypass-approvals-and-sandbox -c 'model_reasoning_effort="xhigh"' '';
      headlessCommand = "${codexHeadless} -c 'model_reasoning_effort=\"xhigh\"'";
      tool = "codex";
      launcherSimple = true;
    }

    # OpenCode (default and profiles)
    {
      alias = "oc";
      command = "opencode --log-level WARN";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = true;
    }
    {
      alias = "ocor";
      command = "opencode_openrouter";
      workflowPromptMode = "flag";
      envMarker = "OPENROUTER";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = true;
    }
    {
      alias = "ocglm";
      command = "opencode_glm";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-glm";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = true;
    }
    {
      alias = "ocgem";
      command = "opencode_gemini";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gemini";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = true;
    }
    {
      alias = "ocgpt";
      command = "opencode_gpt";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = true;
    }
    {
      alias = "locgpt";
      command = "opencode_gpt --model ${gptLowModel}";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt";
      interactiveCommand = "opencode --model ${gptLowModel}";
      headlessCommand = "opencode run --model ${gptLowModel}";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "mocgpt";
      command = "opencode_gpt --model ${gptMedModel}";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt";
      interactiveCommand = "opencode --model ${gptMedModel}";
      headlessCommand = "opencode run --model ${gptMedModel}";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "xocgpt";
      command = "opencode_gpt --model ${gptXHighModel}";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-gpt";
      interactiveCommand = "opencode --model ${gptXHighModel}";
      headlessCommand = "opencode run --model ${gptXHighModel}";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "ocs";
      command = "opencode_sonnet";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-sonnet";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = true;
    }
    {
      alias = "oczen";
      command = "opencode_zen";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-zen";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = true;
    }

    # OpenCode persona profiles
    {
      alias = "ochep";
      command = "opencode_hephaestus";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-hephaestus";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "ocpro";
      command = "opencode_prometheus";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-prometheus";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "ocsis";
      command = "opencode_sisyphus";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-sisyphus";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "ocatl";
      command = "opencode_atlas";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-atlas";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "ocora";
      command = "opencode_oracle";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-oracle";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "oclib";
      command = "opencode_librarian";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-librarian";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "ocexp";
      command = "opencode_explore";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-explore";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "ocmet";
      command = "opencode_metis";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-metis";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "ocmom";
      command = "opencode_momus";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-momus";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "ocmulti";
      command = "opencode_multimodal";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-multimodal";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = false;
    }
    {
      alias = "ocsk";
      command = "opencode_deepseek";
      workflowPromptMode = "flag";
      envMarker = "OPENCODE_CONFIG_DIR=$HOME/.config/opencode-deepseek";
      interactiveCommand = "opencode";
      headlessCommand = "opencode run";
      tool = "opencode";
      launcherSimple = true;
    }

    # Antigravity CLI
    {
      alias = "ag";
      command = "agy --dangerously-skip-permissions";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "agy --dangerously-skip-permissions";
      headlessCommand = "agy --dangerously-skip-permissions --prompt";
      tool = "antigravity";
      launcherSimple = true;
    }
    {
      alias = "gem";
      command = "agy --dangerously-skip-permissions";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "agy --dangerously-skip-permissions";
      headlessCommand = "agy --dangerously-skip-permissions --prompt";
      tool = "antigravity";
      launcherSimple = false;
    }

    # oh-my-pi (opi)
    {
      alias = "opi";
      command = "omp_glm";
      workflowPromptMode = "flag";
      envMarker = "ZAI_OMP";
      interactiveCommand = "omp";
      headlessCommand = "omp --prompt";
      tool = "omp";
      launcherSimple = false;
    }

    # Oh My Pi profiles — omp prefix
    {
      alias = "omp";
      command = "omp";
      workflowPromptMode = "flag";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.omp/profiles/omp";
      interactiveCommand = "omp";
      headlessCommand = "omp -p";
      tool = "omp";
      launcherSimple = false;
    }
    {
      alias = "omps";
      command = "omp_sonnet";
      workflowPromptMode = "flag";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.omp/profiles/omp-sonnet";
      interactiveCommand = "omp";
      headlessCommand = "omp -p";
      tool = "omp";
      launcherSimple = false;
    }
    {
      alias = "ompop";
      command = "omp_opus";
      workflowPromptMode = "flag";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.omp/profiles/omp-opus";
      interactiveCommand = "omp";
      headlessCommand = "omp -p";
      tool = "omp";
      launcherSimple = false;
    }
    {
      alias = "ompglm";
      command = "omp_glm";
      workflowPromptMode = "flag";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.omp/profiles/omp-glm";
      interactiveCommand = "omp --model zai/glm-5.1";
      headlessCommand = "omp -p";
      tool = "omp";
      launcherSimple = false;
    }
    {
      alias = "ompgem";
      command = "omp_gemini";
      workflowPromptMode = "flag";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.omp/profiles/omp-gemini";
      interactiveCommand = "omp";
      headlessCommand = "omp -p";
      tool = "omp";
      launcherSimple = false;
    }
    {
      alias = "ompgpt";
      command = "omp_gpt";
      workflowPromptMode = "flag";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.omp/profiles/omp-gpt";
      interactiveCommand = "omp";
      headlessCommand = "omp -p";
      tool = "omp";
      launcherSimple = false;
    }
    {
      alias = "ompor";
      command = "omp_openrouter";
      workflowPromptMode = "flag";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.omp/profiles/omp-openrouter";
      interactiveCommand = "omp";
      headlessCommand = "omp -p";
      tool = "omp";
      launcherSimple = false;
    }
    {
      alias = "ompzen";
      command = "omp_zen";
      workflowPromptMode = "flag";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.omp/profiles/omp-zen";
      interactiveCommand = "omp";
      headlessCommand = "omp -p";
      tool = "omp";
      launcherSimple = false;
    }
    {
      alias = "ompds";
      command = "omp_seek";
      workflowPromptMode = "flag";
      envMarker = "DEEPSEEK";
      interactiveCommand = "omp";
      headlessCommand = "omp -p";
      tool = "omp";
      launcherSimple = false;
    }

    # Pi profiles — pi prefix
    {
      alias = "pi";
      command = "pi";
      workflowPromptMode = "positional";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.pi/profiles/pi";
      interactiveCommand = "pi";
      headlessCommand = "pi -p";
      tool = "pi";
      launcherSimple = false;
    }
    {
      alias = "pis";
      command = "pi_sonnet";
      workflowPromptMode = "positional";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.pi/profiles/pi-sonnet";
      interactiveCommand = "pi";
      headlessCommand = "pi -p";
      tool = "pi";
      launcherSimple = false;
    }
    {
      alias = "piop";
      command = "pi_opus";
      workflowPromptMode = "positional";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.pi/profiles/pi-opus";
      interactiveCommand = "pi";
      headlessCommand = "pi -p";
      tool = "pi";
      launcherSimple = false;
    }
    {
      alias = "piglm";
      command = "pi_glm";
      workflowPromptMode = "positional";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.pi/profiles/pi-glm";
      interactiveCommand = "pi --model zai/glm-5.1";
      headlessCommand = "pi -p";
      tool = "pi";
      launcherSimple = false;
    }
    {
      alias = "pigem";
      command = "pi_gemini";
      workflowPromptMode = "positional";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.pi/profiles/pi-gemini";
      interactiveCommand = "pi";
      headlessCommand = "pi -p";
      tool = "pi";
      launcherSimple = false;
    }
    {
      alias = "pigpt";
      command = "pi_gpt";
      workflowPromptMode = "positional";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.pi/profiles/pi-gpt";
      interactiveCommand = "pi";
      headlessCommand = "pi -p";
      tool = "pi";
      launcherSimple = false;
    }
    {
      alias = "pior";
      command = "pi_openrouter";
      workflowPromptMode = "positional";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.pi/profiles/pi-openrouter";
      interactiveCommand = "pi";
      headlessCommand = "pi -p";
      tool = "pi";
      launcherSimple = false;
    }
    {
      alias = "pizen";
      command = "pi_zen";
      workflowPromptMode = "positional";
      envMarker = "PI_CODING_AGENT_DIR=$HOME/.pi/profiles/pi-zen";
      interactiveCommand = "pi";
      headlessCommand = "pi -p";
      tool = "pi";
      launcherSimple = false;
    }

    # Forge profiles
    {
      alias = "fg";
      command = "forge";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "forge";
      headlessCommand = "forge";
      tool = "forge";
      launcherSimple = false;
    }
    {
      alias = "fgglm";
      command = "forge_glm";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "forge";
      headlessCommand = "forge";
      tool = "forge";
      launcherSimple = false;
    }
    {
      alias = "fggem";
      command = "forge_gemini";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "forge";
      headlessCommand = "forge";
      tool = "forge";
      launcherSimple = false;
    }
    {
      alias = "fggpt";
      command = "forge_gpt";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "forge";
      headlessCommand = "forge";
      tool = "forge";
      launcherSimple = false;
    }
    {
      alias = "fgor";
      command = "forge_openrouter";
      workflowPromptMode = "flag";
      envMarker = "OPENROUTER";
      interactiveCommand = "forge";
      headlessCommand = "forge";
      tool = "forge";
      launcherSimple = false;
    }
    {
      alias = "fgs";
      command = "forge_sonnet";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "forge";
      headlessCommand = "forge";
      tool = "forge";
      launcherSimple = false;
    }
    {
      alias = "fgzen";
      command = "forge_zen";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "forge";
      headlessCommand = "forge";
      tool = "forge";
      launcherSimple = false;
    }
    {
      alias = "fgds";
      command = "forge_deepseek";
      workflowPromptMode = "flag";
      envMarker = "DEEPSEEK";
      interactiveCommand = "forge";
      headlessCommand = "forge";
      tool = "forge";
      launcherSimple = false;
    }

    # Factory.ai Droid
    {
      alias = "dr";
      command = "droid";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "droid";
      headlessCommand = "droid";
      tool = "droid";
      launcherSimple = true;
    }
    {
      alias = "drglm";
      command = "droid_glm";
      workflowPromptMode = "flag";
      envMarker = "ZAI";
      interactiveCommand = "droid";
      headlessCommand = "droid";
      tool = "droid";
      launcherSimple = true;
    }
    {
      alias = "drgem";
      command = "droid_gemini";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "droid";
      headlessCommand = "droid";
      tool = "droid";
      launcherSimple = true;
    }
    {
      alias = "drgpt";
      command = "droid_gpt";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "droid";
      headlessCommand = "droid";
      tool = "droid";
      launcherSimple = true;
    }
    {
      alias = "dror";
      command = "droid_openrouter";
      workflowPromptMode = "flag";
      envMarker = "OPENROUTER";
      interactiveCommand = "droid";
      headlessCommand = "droid";
      tool = "droid";
      launcherSimple = true;
    }
    {
      alias = "drs";
      command = "droid_sonnet";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "droid";
      headlessCommand = "droid";
      tool = "droid";
      launcherSimple = true;
    }
    {
      alias = "drzen";
      command = "droid_zen";
      workflowPromptMode = "flag";
      envMarker = "-";
      interactiveCommand = "droid";
      headlessCommand = "droid";
      tool = "droid";
      launcherSimple = true;
    }
    {
      alias = "drsk";
      command = "droid_seek";
      workflowPromptMode = "flag";
      envMarker = "DEEPSEEK";
      interactiveCommand = "droid";
      headlessCommand = "droid exec";
      tool = "droid";
      launcherSimple = false;
    }
  ];

  # Workflow prompt specs with labels for bash WORKFLOW_MAP generation.
  workflowPromptSpecs = [
    {
      suffix = "cm";
      prompt = commitSplitPrompt;
      envVar = "COMMIT_SPLIT_PROMPT";
      label = "commit split (cm) — Splits working tree into logical commits with validated, minimal staging.";
    }
    {
      suffix = "rf";
      prompt = refactorMaintainabilityPrompt;
      envVar = "REFACTOR_MAINTAINABILITY_PROMPT";
      label = "refactor maintainability (rf) — Improves structure and clarity without changing behavior, APIs, or workflows.";
    }
    {
      suffix = "fx";
      prompt = bugfixRootCausePrompt;
      envVar = "BUGFIX_ROOT_CAUSE_PROMPT";
      label = "bugfix root cause (fx) — Reproduces bugs, proves root cause, fixes minimally, validates regressions afterward.";
    }
    {
      suffix = "sa";
      prompt = securityAuditPrompt;
      envVar = "SECURITY_AUDIT_PROMPT";
      label = "security audit (sa) — Finds evidence-backed security weaknesses across code, configs, dependencies, infrastructure surfaces.";
    }
    {
      suffix = "du";
      prompt = dependencyUpgradePrompt;
      envVar = "DEPENDENCY_UPGRADE_PROMPT";
      label = "dependency upgrade (du) — Upgrades dependencies safely, handles breaking changes, validates compatibility, reports blockers.";
    }
    {
      suffix = "bp";
      prompt = buildPerformancePrompt;
      envVar = "BUILD_PERFORMANCE_PROMPT";
      label = "build performance (bp) — Measures bottlenecks, applies low-risk optimizations, compares before-and-after performance evidence clearly.";
    }
    {
      suffix = "rp";
      prompt = runtimePerformancePrompt;
      envVar = "RUNTIME_PERFORMANCE_PROMPT";
      label = "runtime performance (rp) — Measures real code-path bottlenecks, applies low-risk optimizations, and verifies before-and-after latency, throughput, or memory gains.";
    }
    {
      suffix = "md";
      prompt = markdownSyncPrompt;
      envVar = "MARKDOWN_SYNC_PROMPT";
      label = "markdown sync (md) — Synchronizes documentation with repository reality, removing drift, ambiguity, stale instructions.";
    }
  ];

  workflowAgentSpecs = builtins.filter (agent: agent ? workflowPromptMode) aiAgentAliasSpecs;

  aiWorkflowAliasSpecs = lib.flatten (
    map (
      workflow:
      let
        flatPrompt = flattenForAlias workflow.prompt;
      in
      map (agent: {
        alias = "${agent.alias}${workflow.suffix}";
        command =
          if agent.workflowPromptMode == "flag" then
            "_ai_agent_exec ${agent.alias}${workflow.suffix} -- ${agent.command} --prompt ${lib.escapeShellArg flatPrompt}"
          else
            "_ai_agent_exec ${agent.alias}${workflow.suffix} -- ${agent.command} ${lib.escapeShellArg flatPrompt}";
      }) workflowAgentSpecs
    ) workflowPromptSpecs
  );

  workflowClipboardAliasSpecs = map (
    workflow:
    let
      flatPrompt = flattenForAlias workflow.prompt;
    in
    {
      alias = "cp${workflow.suffix}";
      command =
        "if command -v wl-copy >/dev/null 2>&1; then printf '%s' ${lib.escapeShellArg flatPrompt} | wl-copy; "
        + "elif command -v xclip >/dev/null 2>&1; then printf '%s' ${lib.escapeShellArg flatPrompt} | xclip -selection clipboard; "
        + "else echo 'Clipboard tool not found (need wl-copy or xclip)' >&2; false; fi "
        + "&& echo 'Copied ${workflow.suffix} prompt to clipboard'";
    }
  ) workflowPromptSpecs;

  aiAliases = mkAliasAttrs (
    (map (
      spec: spec // { command = "_ai_agent_exec ${spec.alias} -- ${spec.command}"; }
    ) aiAgentAliasSpecs)
    ++ aiWorkflowAliasSpecs
    ++ workflowClipboardAliasSpecs
  );

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

  # --- Bash registry generation ---

  escapeForBashDoubleQuote = s: builtins.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] s;

  envMarkerNeedsQuoting = marker: builtins.match ".*\\$.*" marker != null;

  mkRegistryLine =
    spec:
    let
      envPart =
        if spec.envMarker == "-" then
          "-"
        else if envMarkerNeedsQuoting spec.envMarker then
          "\"${spec.envMarker}\""
        else
          spec.envMarker;
      interactivePart = "\"${escapeForBashDoubleQuote spec.interactiveCommand}\"";
      headlessPart = "\"${escapeForBashDoubleQuote spec.headlessCommand}\"";
    in
    "_def ${spec.alias}    ${envPart}    ${interactivePart}    ${headlessPart}";

  tools = lib.unique (map (spec: spec.tool) aiAgentAliasSpecs);
  simpleAliases = map (spec: spec.alias) (lib.filter (spec: spec.launcherSimple) aiAgentAliasSpecs);
  defLines = map mkRegistryLine aiAgentAliasSpecs;
  workflowSuffixes = map (spec: spec.suffix) workflowPromptSpecs;

  workflowMapEntries = map (
    spec: "  [${spec.suffix}]=\"${spec.label}|${spec.envVar}\""
  ) workflowPromptSpecs;

  aliasToolEntries = map (spec: "  [${spec.alias}]=\"${spec.tool}\"") aiAgentAliasSpecs;

  providerLabels = {
    opencode = "OpenCode";
    claude = "Claude Code";
    codex = "Codex";
    antigravity = "Antigravity";
    omp = "Oh My Pi";
    droid = "Droid";
  };
  providerLabelEntries = lib.mapAttrsToList (tool: label: "  [${tool}]=\"${label}\"") providerLabels;

  providerOrder = [
    "opencode"
    "claude"
    "codex"
    "antigravity"
    "omp"
    "droid"
  ];

  generatedBashRegistry = builtins.concatStringsSep "\n" (
    [
      "# Auto-generated alias registry — do not edit."
      "# Regenerate with: just home"
      "# Source: home-manager/modules/ai-agents/helpers/_aliases.nix"
      ""
      "# --- Agent registries (populated via _def from _agent-registry.sh) ---"
    ]
    ++ defLines
    ++ [
      ""
      "# --- Supported tools ---"
      "SUPPORTED_TOOLS=(${builtins.concatStringsSep " " tools})"
      ""
      "# --- Simple aliases for launcher quick-pick ---"
      "LAUNCHER_SIMPLE_ALIASES=(${builtins.concatStringsSep " " simpleAliases})"
      ""
      "# --- Alias -> tool mapping ---"
      "declare -A ALIAS_TOOLS=("
    ]
    ++ aliasToolEntries
    ++ [
      ")"
      ""
      "# --- Provider display labels and order ---"
      "PROVIDER_ORDER=(${builtins.concatStringsSep " " providerOrder})"
      "declare -A PROVIDER_LABELS=("
    ]
    ++ providerLabelEntries
    ++ [
      ")"
      ""
      "# --- Workflow suffixes ---"
      "WORKFLOW_SUFFIXES=(${builtins.concatStringsSep " " workflowSuffixes})"
      ""
      "# --- Workflow metadata: suffix -> \"label|env_var\" ---"
      "declare -A WORKFLOW_MAP=("
    ]
    ++ workflowMapEntries
    ++ [ ")" ]
  );
in
{
  inherit
    aiAliases
    aiAgentLauncher
    generatedBashRegistry
    workflowPrompts
    mkWorkflowEnvVars
    ;
  aiAgentInventory = pkgs.writeShellScriptBin "ai-agent-inventory" ''
    exec ${scriptsDir}/ai/agent-inventory.sh "$@"
  '';
}
