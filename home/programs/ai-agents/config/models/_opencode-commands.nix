# OpenCode slash command definitions (workflow prompts).

{ workflowPrompts }:

{
  "commit-split" = {
    description = "Split current changes into minimal logical signed commits";
    agent = "build";
    subtask = true;
    template = workflowPrompts.commitSplit;
  };
  refactor = {
    description = "Raise maintainability without behavior drift";
    agent = "build";
    subtask = true;
    template = workflowPrompts.refactorMaintainability;
  };
  "security-audit" = {
    description = "Run an evidence-first security review";
    agent = "build";
    subtask = true;
    template = workflowPrompts.securityAudit;
  };
  "build-perf" = {
    description = "Measure and improve build bottlenecks";
    agent = "build";
    subtask = true;
    template = workflowPrompts.buildPerformance;
  };
  "runtime-perf" = {
    description = "Measure and improve runtime/code bottlenecks";
    agent = "build";
    subtask = true;
    template = workflowPrompts.runtimePerformance;
  };
  "markdown-sync" = {
    description = "Sync docs with current repository behavior";
    agent = "build";
    subtask = true;
    template = workflowPrompts.markdownSync;
  };
}
