# Skill installations for all AI agents.
# Imported by config/defaults.nix.
#
# EMPTY BY DESIGN: OpenCode and MiMoCode pre-load ALL skills at session start,
# consuming ~52K tokens (882 skills). Claude Code loads skills on-demand (~10K).
# Both scan ~/.claude/skills/ — no filesystem isolation is possible.
#
# To install skills temporarily: just skill-add <repo>
# To restore permanently: add repos below + just skills-rebuild + nh home switch
{
  skills = [ ];
}
