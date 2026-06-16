# Cleanup for disabled github/spec-kit.
#
# Removes all speckit-*.md command files from Claude Code and Codex, and
# speckit.*.md from every OpenCode profile when the top-level `speckit.enable`
# is false.  Thorough cleanup avoids orphaned files from a previous activation.

{
  cfg,
  lib,
  opencodeProfileNames,
}:

let
  speckitCfg = cfg.speckit;
in

{
  cleanupDisabledSpecKit = lib.mkIf (!speckitCfg.enable) (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      rm -f "$HOME/.claude/commands/speckit-"*.md 2>/dev/null || true
      rm -f "$HOME/.codex/commands/speckit-"*.md 2>/dev/null || true
      for profile in ${lib.concatStringsSep " " (map lib.escapeShellArg opencodeProfileNames)}; do
        rm -f "$HOME/.config/$profile/commands/speckit."*.md 2>/dev/null || true
      done
      rm -rf "$HOME/.local/share/spec-kit"
    ''
  );
}
