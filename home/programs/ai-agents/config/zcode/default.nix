# ZCode configuration: custom subagents and lifecycle hooks.

{ lib, ... }:

{
  programs.aiAgents.zcode = {
    agents = import ./_agents.nix { inherit lib; };
    hooks = import ./_hooks.nix { inherit lib; };
  };
}
