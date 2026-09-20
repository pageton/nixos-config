# Codex CLI configuration: model, profiles, custom agents, and developer instructions.

{ config, ... }:

{
  programs.aiAgents.codex = {
    enable = true;
    model = "gpt-5.6-sol";
    sandboxMode = "danger-full-access";
    enableSearch = false;
    personality = "pragmatic";
    reasoningEffort = "high";
    approvalPolicy = "never";
    features = {
      apps = false;
      hooks = true;
      multi_agent = true;
      plugins = true;
      shell_snapshot = true;
      tool_suggest = true;
      unified_exec = true;
    };
    trustedProjects = [ "${config.home.homeDirectory}/System" ];
    profiles = {
      quick = {
        reasoningEffort = "low";
        approvalPolicy = "never";
        sandboxMode = "danger-full-access";
      };
      deep = {
        reasoningEffort = "xhigh";
        approvalPolicy = "never";
        sandboxMode = "danger-full-access";
      };
      safe = {
        approvalPolicy = "never";
        sandboxMode = "danger-full-access";
      };
      review = {
        personality = "pragmatic";
        reasoningEffort = "high";
        approvalPolicy = "never";
        sandboxMode = "danger-full-access";
        developerInstructions = ''
          Run in review mode. Prioritize bugs, regressions, security issues, and missing tests.
          Findings come first with exact file and line references when available.
        '';
      };
    };
    customAgents = {
      reviewer = {
        description = "Review-focused agent for bugs, regressions, security issues, and missing tests.";
        reasoningEffort = "high";
        approvalPolicy = "never";
        sandboxMode = "danger-full-access";
        developerInstructions = ''
          Perform code review only. Do not implement changes.
          Prioritize correctness, behavior drift, security issues, and test gaps.
          Findings must be concise, ordered by severity, and include exact evidence.
        '';
      };
      recon = {
        description = "Read-heavy reverse-engineering triage agent for static inspection and evidence gathering.";
        reasoningEffort = "high";
        approvalPolicy = "never";
        sandboxMode = "danger-full-access";
        enableSearch = true;
        developerInstructions = ''
          Focus on static triage and evidence gathering.
          Map strings, imports, symbols, embedded endpoints, protocols, config formats, and trust boundaries.
          Do not mutate files or run samples unless explicitly asked.
        '';
      };
      explorer = {
        description = "Read-heavy codebase exploration, file tracing, and evidence gathering.";
        reasoningEffort = "medium";
        approvalPolicy = "never";
        sandboxMode = "read-only";
        developerInstructions = ''
          Stay in exploration mode. Trace the real execution path, cite files and symbols,
          and do not edit files. Return concise evidence summaries with exact paths.
        '';
      };
      worker = {
        description = "Targeted implementation and fixes after the task is understood.";
        reasoningEffort = "medium";
        approvalPolicy = "never";
        sandboxMode = "danger-full-access";
        developerInstructions = ''
          Own the fix once the task is understood. Make the smallest defensible change,
          keep unrelated files untouched, and validate only the behavior you changed.
        '';
      };
      monitor = {
        description = "Long-running command, build, and polling monitor with concise status updates.";
        reasoningEffort = "low";
        approvalPolicy = "never";
        sandboxMode = "danger-full-access";
        developerInstructions = ''
          Monitor long-running commands and builds. Poll efficiently instead of idle-waiting,
          and report concise status with exact commands and observed output.
        '';
      };
    };
    extraToml = ''
      plan_mode_reasoning_effort = "high"
      model_verbosity = "low"

      [agents]
      enabled = true
      max_concurrent_threads_per_session = 6
      default_subagent_reasoning_effort = "medium"
    '';
  };
}
