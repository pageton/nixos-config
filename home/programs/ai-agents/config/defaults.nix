# Base AI agent defaults: enablement, shared instructions, and skill sets.

_:

let
  skillDefs = import ./_skills.nix;
in
{
  programs.aiAgents = {
    enable = true;
    globalInstructions = builtins.readFile ./global-instructions.md;
    everythingClaudeCode.enable = true;
    speckit.enable = true;
    agencyAgents.enable = false;
    impeccable.enable = true;
    agentmemory.enable = true;
    herdr.enable = true;
    antigravity.enable = true;
    omp.enable = true;
    codegraph.enable = true;
    serena.enable = false;

    inherit (skillDefs) skills;
  };
}
