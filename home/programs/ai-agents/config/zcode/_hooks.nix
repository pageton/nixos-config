# ZCode lifecycle hooks adapted from the shared Claude Code hook definitions.
# ZCode accepts Claude-compatible stdin fields and command hooks, but uses a
# smaller event set plus native async/timeoutMs executor fields.
#
# This module runs build-time assertions so misconfiguration fails loudly at
# `nix eval`/`nh switch` time rather than silently producing broken hooks.

{ lib }:

let
  inherit (builtins)
    all
    attrNames
    concatStringsSep
    elem
    filter
    hasAttr
    isAttrs
    isList
    isString
    ;
  inherit (lib)
    assertMsg
    filterAttrs
    hasInfix
    mapAttrs
    optionalAttrs
    removeAttrs
    ;

  claudeHooks = import ../claude/_hooks.nix { includeHerdr = false; };
  zcodeHookSets = [ (import ./_hooks-go-git.nix) ];

  supportedEvents = [
    "SessionStart"
    "UserPromptSubmit"
    "PreToolUse"
    "PermissionRequest"
    "PostToolUse"
    "PostToolUseFailure"
    "Stop"
  ];

  # Keys a ZCode hook executor may carry after adaptation. Anything else means
  # the upstream Claude schema gained a field this adapter doesn't translate.
  allowedExecutorKeys = [
    "type"
    "command"
    "enabled"
    "async"
    "timeoutMs"
  ];

  # Keys a ZCode hook *entry* (matcher group) may carry.
  allowedEntryKeys = [
    "matcher"
    "hooks"
  ];

  # --- adaptation ---------------------------------------------------------

  # Substitutions that must ALL remain present in the source so the adapter can
  # prove it translated them. If an upstream rename drops one, the build fails.
  requiredClaudeSubstrings = [
    "$HOME/.claude/session-state"
    "Claude Code"
    "outside Claude"
    "gofmt"
  ];

  commandReplacements = {
    "$HOME/.claude/session-state" = "$HOME/.zcode/session-state";
    "Claude Code" = "ZCode";
    "outside Claude" = "outside ZCode";
    "command -v gofmt" = "command -v gofumpt";
    "gofmt -w" = "gofumpt -w";
  };

  adaptCommand =
    command:
    let
      fromList = attrNames commandReplacements;
      toList = map (k: commandReplacements.${k}) fromList;
    in
    builtins.replaceStrings fromList toList command;

  adaptExecutor =
    executor:
    let
      adapted =
        (removeAttrs executor [
          "run_in_background"
          "timeout"
        ])
        // {
          enabled = executor.enabled or true;
        }
        // optionalAttrs (executor ? command) { command = adaptCommand executor.command; }
        // optionalAttrs (executor.run_in_background or false) { async = true; }
        // optionalAttrs (executor ? timeout) {
          # Existing shared hook values are expressed in milliseconds.
          timeoutMs = executor.timeout;
        };
      leftover = filter (k: !(elem k allowedExecutorKeys)) (attrNames adapted);
    in
    assert assertMsg (
      leftover == [ ]
    ) "ZCode hook executor has untranslated fields after adaptation: ${concatStringsSep ", " leftover}";
    adapted;

  adaptEntry =
    entry:
    let
      leftover = filter (k: !(elem k allowedEntryKeys)) (attrNames entry);
    in
    assert assertMsg (
      leftover == [ ]
    ) "ZCode hook entry has unsupported fields: ${concatStringsSep ", " leftover}";
    assert assertMsg (
      hasAttr "hooks" entry && isList entry.hooks
    ) "ZCode hook entry is missing a 'hooks' list";
    entry // { hooks = map adaptExecutor entry.hooks; };

  # --- validation helpers -------------------------------------------------

  # Prove every required Claude substring still appears somewhere in the
  # aggregated Claude source, so a rename upstream fails the build instead of
  # silently leaking a stale Claude-specific path into ZCode.
  allClaudeCommands = concatStringsSep "\n" (
    builtins.concatMap (
      event:
      builtins.concatMap (
        entry: builtins.concatMap (executor: [ (executor.command or "") ]) entry.hooks
      ) (claudeHooks.${event} or [ ])
    ) supportedEvents
  );

  missingSubstrings = filter (s: !(hasInfix s allClaudeCommands)) requiredClaudeSubstrings;

  # Reject any event a ZCode hook set declares that isn't in supportedEvents.
  unsupportedDeclaredEvents = builtins.concatMap (
    hookSet: filter (event: !(elem event supportedEvents)) (attrNames hookSet)
  ) zcodeHookSets;

  # --- assembly -----------------------------------------------------------

  selectedEvents = builtins.listToAttrs (
    map (event: {
      name = event;
      value = map adaptEntry (claudeHooks.${event} or [ ]);
    }) supportedEvents
  );

  mergedEvents = mapAttrs (
    event: entries: entries ++ builtins.concatMap (hookSet: hookSet.${event} or [ ]) zcodeHookSets
  ) selectedEvents;

  # Adapt entries contributed by ZCode-native hook sets too (they bypass the
  # Claude adapter above), then validate them with the same rules.
  fullyAdapted = mapAttrs (_event: entries: map adaptEntry entries) mergedEvents;
in
assert assertMsg (missingSubstrings == [ ])
  "ZCode hook adapter can no longer find expected Claude substrings to replace; upstream likely renamed: ${concatStringsSep ", " missingSubstrings}";
assert assertMsg (unsupportedDeclaredEvents == [ ])
  "ZCode hook set declares events not in supportedEvents: ${concatStringsSep ", " unsupportedDeclaredEvents}";
filterAttrs (_event: entries: entries != [ ]) fullyAdapted
