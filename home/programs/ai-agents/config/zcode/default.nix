# ZCode configuration: orchestration commands, custom subagents, and lifecycle hooks.

{ lib, ... }:

{
  programs.aiAgents.zcode = {
    agents = import ./_agents.nix { inherit lib; };
    commands = import ./_commands.nix;
    hooks = import ./_hooks.nix { inherit lib; };
  };
}
