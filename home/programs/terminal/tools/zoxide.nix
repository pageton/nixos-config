# Zoxide (fast directory changer) configuration.
# This module configures zoxide, a fast alternative to cd that learns
# your directory navigation patterns and provides smart directory jumping.

{ pkgs, ... }:

{
  programs.zoxide = {
    enable = true; # Enable zoxide for smart directory navigation
    package = pkgs.zoxide; # Use the standard zoxide package
    enableZshIntegration = true; # Enable Zsh shell integration for auto-completion
  };
}
