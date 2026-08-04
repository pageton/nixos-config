# ZCode lifecycle hooks adapted from the shared Claude Code hook definitions.
# ZCode accepts Claude-compatible stdin fields and command hooks, but uses a
# smaller event set plus native async/timeoutMs executor fields.

{ lib }:

let
  claudeHooks = import ../claude/_hooks.nix { includeHerdr = false; };
  zcodeHookSets = [
    (import ./_hooks-go-git.nix)
    (import ./_hooks-orchestration.nix)
  ];

  supportedEvents = [
    "SessionStart"
    "UserPromptSubmit"
    "PreToolUse"
    "PermissionRequest"
    "PostToolUse"
    "PostToolUseFailure"
    "Stop"
  ];

  adaptCommand =
    command:
    builtins.replaceStrings
      [ "$HOME/.claude/session-state" "Claude Code" "outside Claude" "command -v gofmt" "gofmt -w" ]
      [ "$HOME/.zcode/session-state" "ZCode" "outside ZCode" "command -v gofumpt" "gofumpt -w" ]
      command;

  adaptExecutor =
    executor:
    (removeAttrs executor [
      "run_in_background"
      "timeout"
    ])
    // {
      enabled = executor.enabled or true;
    }
    // lib.optionalAttrs (executor ? command) { command = adaptCommand executor.command; }
    // lib.optionalAttrs (executor.run_in_background or false) { async = true; }
    // lib.optionalAttrs (executor ? timeout) {
      # Existing shared hook values are expressed in milliseconds.
      timeoutMs = executor.timeout;
    };

  adaptEntry = entry: entry // { hooks = map adaptExecutor entry.hooks; };

  selectedEvents = builtins.listToAttrs (
    map (event: {
      name = event;
      value = map adaptEntry (claudeHooks.${event} or [ ]);
    }) supportedEvents
  );

  mergedEvents = builtins.mapAttrs (
    event: entries: entries ++ lib.concatMap (hookSet: hookSet.${event} or [ ]) zcodeHookSets
  ) selectedEvents;
in
lib.filterAttrs (_event: entries: entries != [ ]) mergedEvents
