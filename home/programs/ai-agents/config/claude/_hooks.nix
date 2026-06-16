# Lifecycle hook configuration for Claude Code — aggregates per-stage hook modules.

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
  postToolUse = import ./_hooks-post-tool-use.nix {
    inherit mkFormatterHook formatterRegistry mkCommandHook;
  };
  session = import ./_hooks-session.nix { inherit mkPassthroughHook; };
  herdr = import ./_hooks-herdr.nix { };
  security = import ./_hooks-security.nix { inherit mkCommandHook; };
  projectGuards = import ./_hooks-project-guards.nix { inherit mkCommandHook; };

  # Both session and herdr register SessionStart hooks — concatenate the lists
  # so the AGENTS.md context loader and herdr's session reporter both fire.
  # (Plain // would let herdr clobber session's SessionStart entries.)
  sessionStartMerged = {
    SessionStart = (session.SessionStart or [ ]) ++ (herdr.SessionStart or [ ]);
  };
in
preToolUse // postToolUse // session // sessionStartMerged // security // projectGuards
