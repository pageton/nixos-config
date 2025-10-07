# Custom scripts module
# This module adds various utility scripts to the system PATH

{ pkgs, user, ... }:

{
  # Add custom scripts to system packages
  environment.systemPackages = with pkgs; [
    # AI assistant scripts
    (writeShellScriptBin "ai-ask" ''
      # AI assistant with z.ai API - ask questions and get intelligent responses
      # Usage: ask [-d] [-c] [-s "system prompt"] "your question"
      exec /home/${user}/System/scripts/ai/ask.sh "$@"
    '')

    (writeShellScriptBin "ai-help" ''
      # Command assistance with AI - get command suggestions
      # Usage: help "how to do something" (automatically copies to clipboard)
      exec /home/${user}/System/scripts/ai/help.sh "$@"
    '')

    (writeShellScriptBin "ai-commit" ''
      # Generate conventional commit messages using AI based on staged changes
      # Usage: commit (in any git repository)
      # Analyzes staged changes and generates conventional commit message
      exec /home/${user}/System/scripts/ai/commit.sh "$@"
    '')
  ];

  # Ensure scripts have proper permissions
  systemd.tmpfiles.rules = [ "d /home/${user}/.local/bin 0755 ${user} users -" ];
}
