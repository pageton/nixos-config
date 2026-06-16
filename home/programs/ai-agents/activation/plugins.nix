# Plugin installation and cleanup — aggregates per-plugin modules.

# modules-check: manual-helper ./secrets.nix ./codex-setup.nix ./claude-setup.nix ./plugins.nix ./skills.nix

{
  cfg,
  pkgs,
  lib,
  opencodeProfileNames,
  config,
}:

let
  fileTemplates = import ../helpers/_file-templates.nix;
  preservedClaudeAgents = builtins.attrNames fileTemplates.claudeAgents;

  impeccable = import ./_plugin-impeccable.nix {
    inherit
      cfg
      pkgs
      lib
      opencodeProfileNames
      ;
  };
  agencyAgents = import ./_plugin-agency-agents.nix { inherit cfg pkgs lib; };
  everythingClaudeCode = import ./_plugin-everything-claude-code.nix {
    inherit
      cfg
      pkgs
      lib
      opencodeProfileNames
      ;
  };
  specKit = import ./_plugin-spec-kit.nix {
    inherit
      cfg
      pkgs
      lib
      opencodeProfileNames
      ;
  };
  cleanupAgencyAgents = import ./_cleanup-agency-agents.nix {
    inherit cfg lib preservedClaudeAgents;
  };
  cleanupEverythingClaudeCode = import ./_cleanup-everything-claude-code.nix {
    inherit cfg lib opencodeProfileNames;
  };
  cleanupSpecKit = import ./_cleanup-spec-kit.nix { inherit cfg lib opencodeProfileNames; };
in
impeccable
// agencyAgents
// everythingClaudeCode
// specKit
// cleanupAgencyAgents
// cleanupEverythingClaudeCode
// cleanupSpecKit
