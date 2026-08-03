# ZCode configuration: lifecycle hooks adapted from the Claude Code policy set.

{ lib, ... }:

{ programs.aiAgents.zcode.hooks = import ./_hooks.nix { inherit lib; }; }
