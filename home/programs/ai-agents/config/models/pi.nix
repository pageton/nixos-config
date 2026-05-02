# Pi (badlogic/pi-mono) coding agent default configuration.

{ ... }:

{
  programs.aiAgents.pi = {
    enable = true;

    # Skills are deployed to ~/.pi/agent/skills/ by files.nix (custom skills)
    # and skills.nix (mirrored from ~/.claude/skills/).
    skills = [ "~/.pi/agent/skills" ];
  };
}
