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

  hook-list = ''
    ---
    description: List every centralized orchestration hook and its effective state.
    ---
    Call `hooks_list` on the `zcode-orchestrator` MCP server with `state` set to
    `all`. Report hook id, event, enabled state, priority, mode, failure policy,
    capabilities, and whether the hook is mandatory.
  '';

  hook-enabled = ''
    ---
    description: List enabled centralized orchestration hooks.
    ---
    Call `hooks_list` on the `zcode-orchestrator` MCP server with `state` set to
    `enabled`. Return the enabled hook ids grouped by event.
  '';

  hook-disabled = ''
    ---
    description: List disabled centralized orchestration hooks.
    ---
    Call `hooks_list` on the `zcode-orchestrator` MCP server with `state` set to
    `disabled`. Return the disabled hook ids grouped by event.
  '';

  hook-detail = ''
    ---
    description: Inspect one centralized hook definition and recent executions.
    argument-hint: <hook-id>
    ---
    Call `hook_detail` on the `zcode-orchestrator` MCP server with hook id
    `$ARGUMENTS`. Report the complete definition, effective state, and recent
    bounded execution records.
  '';

  hook-enable = ''
    ---
    description: Enable one configurable centralized hook.
    argument-hint: <hook-id>
    ---
    Call `hook_enable` on the `zcode-orchestrator` MCP server with hook id
    `$ARGUMENTS`. Report the updated effective state. Mandatory hooks remain
    enabled and need no override.
  '';

  hook-disable = ''
    ---
    description: Disable one non-mandatory centralized hook.
    argument-hint: <hook-id>
    ---
    Call `hook_disable` on the `zcode-orchestrator` MCP server with hook id
    `$ARGUMENTS`. Report the updated effective state. Never bypass or suppress
    an error when a mandatory safety hook rejects disablement.
  '';

  hook-events = ''
    ---
    description: List supported orchestration hook events and registered hooks.
    ---
    Call `hook_events` on the `zcode-orchestrator` MCP server. Report every
    event name and its registered hook ids in execution order.
  '';

  review = ''
    ---
    description: Review a path or change set for correctness, regressions, security, and missing tests.
    argument-hint: <path-or-scope> [focus]
    ---
    Review `$ARGUMENTS` without modifying files or Git state.

    Inspect the implementation, its callers, relevant tests, and repository
    conventions. Report findings first, ordered by severity. For each finding,
    include an exact file and line reference, the observable failure mode, and
    the smallest safe correction. Distinguish verified defects from inference.
    If no actionable findings remain, say so and name any unverified risk.
  '';

  commit-message = ''
    ---
    description: Draft a semantic commit message from the current Git changes without committing.
    argument-hint: [scope-or-extra-context]
    ---
    Inspect the current branch, staged changes, unstaged changes, and relevant
    recent history. Use `$ARGUMENTS` only as additional context.

    Return one recommended semantic commit subject of at most 72 characters
    and an optional concise body when the rationale is not obvious. Describe
    the actual behavior change; do not claim tests or outcomes that were not
    observed. Do not stage, commit, push, or alter the worktree.
  '';

  release-check = ''
    ---
    description: Evaluate release readiness using the repository's own validation workflow.
    argument-hint: [version-or-release-scope]
    ---
    Evaluate release readiness for `$ARGUMENTS`.

    Read the repository release instructions and identify the affected
    package or application. Inspect versioning, generated artifacts,
    changelog/release notes, dependency state, and residual Git changes. Run
    the narrowest repository-provided checks needed to verify the release
    contract, without publishing, tagging, committing, or pushing. Report
    blockers first, then passed checks and remaining manual release steps.
  '';

  explain-file = ''
    ---
    description: Explain a file's purpose, data flow, dependencies, and maintenance risks.
    argument-hint: <file-path> [question]
    ---
    Explain `$ARGUMENTS` from current repository evidence.

    Cover the file's responsibility, important symbols, inputs and outputs,
    callers and dependencies, state or side effects, error paths, and relevant
    tests. Cite exact file and line references. Focus on details a maintainer
    needs to modify the file safely; avoid restating every line.
  '';
}
