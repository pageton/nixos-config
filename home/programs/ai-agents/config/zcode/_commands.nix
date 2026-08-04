{
  agent-run = ''
    ---
    description: Classify, plan, execute, and evaluate a task through the centralized ZCode orchestrator.
    argument-hint: <task>
    ---
    Use only the `zcode-orchestrator` MCP server for orchestration.

    1. Call `orchestrate` with `task` set to `$ARGUMENTS`, the current workspace,
       and `mode` set to `execute`.
    2. If the result is `awaiting_approval`, display its exact `APPROVE RUN`
       phrase and stop. Do not paraphrase, consume, or bypass it.
    3. Otherwise poll `orchestration_status` with bounded waits until the run is terminal.
    4. Report selected agents, execution order, task-owned changes, validation,
       findings, blockers, and residual Git state.
    5. Do not call ZCode's Agent tool directly and do not perform Git mutations.
  '';

  agent-plan = ''
    ---
    description: Return a dependency-aware ZCode subagent plan without executing it.
    argument-hint: <task>
    ---
    Call the `zcode-orchestrator` MCP server's `orchestrate` tool with `task` set
    to `$ARGUMENTS`, the current workspace, and `mode` set to `plan`.

    Report the task classification, risk, selected agents, dependency order,
    reader/writer capabilities, and whether execution would require approval.
    Do not execute the plan and do not call the Agent tool directly.
  '';

  agent-status = ''
    ---
    description: Inspect one centralized ZCode orchestration run.
    argument-hint: <run-id>
    ---
    Call `orchestration_status` on the `zcode-orchestrator` MCP server with
    run id `$ARGUMENTS` and a bounded wait. Report each unit's state, attempts,
    structured result, detected task-owned changes, violations, and evaluation.
  '';

  agent-cancel = ''
    ---
    description: Cancel an active centralized ZCode orchestration run.
    argument-hint: <run-id>
    ---
    Call `orchestration_cancel` on the `zcode-orchestrator` MCP server with run
    id `$ARGUMENTS`. Report the final cancellation state. Do not use shell
    process commands as a substitute.
  '';

  agent-git = ''
    ---
    description: Prepare an exact-path signed commit for a completed orchestration run.
    argument-hint: <run-id> <semantic-commit-message> [push]
    ---
    Parse `$ARGUMENTS` into the completed run id, one semantic commit message,
    and whether a normal push was explicitly requested. Inspect the run first,
    then call `git_prepare` on the `zcode-orchestrator` MCP server.

    Display the exact returned `APPROVE GIT` phrase and stop. The subsequent
    exact user approval is recorded by a hook; only then may `git_apply` consume
    that token. Never stage, commit, push, or rewrite history through Bash.
  '';

  agent-rollback = ''
    ---
    description: Prepare a rollback limited to task-owned paths from one orchestration run.
    argument-hint: <run-id> [relative-paths...]
    ---
    Inspect the run, then call `rollback_prepare` on the `zcode-orchestrator`
    MCP server using `$ARGUMENTS`. Omit paths to select all task-owned paths.

    Display the exact returned `APPROVE ROLLBACK` phrase and stop. The subsequent
    exact user approval is recorded by a hook; only then may `rollback_apply`
    consume that token. Never use reset, clean, restore, or deletion commands
    through Bash as a substitute.
  '';
}
