# Lifecycle hook configuration for Claude Code — aggregates per-stage hook modules.

{
  includeHerdr ? true,
}:

let
  helpers = import ./_hooks-helpers.nix;
  inherit (helpers)
    mkFormatterHook
    mkBashHook
    mkCommandHook
    mkPassthroughHook
    formatterRegistry
    ;

  preToolUse = import ./_hooks-pre-tool-use.nix { inherit mkBashHook; };
  postToolUse = import ./_hooks-post-tool-use.nix { inherit mkFormatterHook formatterRegistry; };
  session = import ./_hooks-session.nix { inherit mkPassthroughHook; };
  fileSafety = import ./_hooks-file-safety.nix;
  herdr = import ./_hooks-herdr.nix { };
  security = import ./_hooks-security.nix { inherit mkCommandHook; };
  projectGuards = import ./_hooks-project-guards.nix { inherit mkCommandHook; };

  hookSets = [
    preToolUse
    postToolUse
    session
    fileSafety
  ]
  ++ (if includeHerdr then [ herdr ] else [ ])
  ++ [
    security
    projectGuards
  ];

  # Multiple modules contribute to the same lifecycle event. Concatenate their
  # entries instead of using right-biased attrset merges that discard hooks.
  mergeHookSets = builtins.foldl' (
    merged: hookSet:
    merged // builtins.mapAttrs (event: entries: (merged.${event} or [ ]) ++ entries) hookSet
  ) { };
in
mergeHookSets hookSets
