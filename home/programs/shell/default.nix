# Shell integration and development tools configuration.
# This module configures shell integrations, direnv, and essential Nix development tools
# for an improved development workflow.

{ pkgs, ... }:

{
  # Direnv integration for automatic environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Nix-your-shell for better nix-shell integration
  programs.nix-your-shell = {
    enable = true;
  };

  # Essential Nix development tools
  home.packages = with pkgs; [
    # Nix formatting and linting
    nixfmt-rfc-style # Nix code formatter (RFC 166 style)
    statix # Nix linter for best practices
    deadnix # Find dead code in Nix expressions
    nixd # Nix language server
    nil # Another Nix language server

    # Nix development utilities
    nix-tree # Browse Nix store in a tree view
    nix-output-monitor # Show build output in real-time
    nix-index # Fast package lookup

    # Development utilities
    cachix # Use binary caches for faster builds
    comma # Run nix-shell commands without entering shell
  ];

}
