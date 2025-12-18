{ pkgs, ... }:
pkgs.writeShellScriptBin "ai-help" ''
  # help.sh - AI-powered command assistant
  # Usage: ai-help "how to list files" -> "ls -la" (automatically copied to clipboard)

  set -euo pipefail

  # Colors for output
  GREEN='\033[0;32m'
  BLUE='\033[0;34m'
  # YELLOW='\033[1;33m'  # Currently unused but available for future use
  RED='\033[0;31m'
  NC='\033[0m' # No Color

  # Function to print colored output
  print_info() { echo -e "''${BLUE}ℹ''${NC} $1"; }
  print_success() { echo -e "''${GREEN}✓''${NC} $1"; }
  print_error() { echo -e "''${RED}✗''${NC} $1"; }

  # Function to show usage
  show_usage() {
      echo "Usage: ai-help \"your question about commands\""
      echo ""
      echo "Examples:"
      echo "  ai-help \"how to list files\""
      echo "  ai-help \"find large files in directory\""
      echo "  ai-help \"compress a folder\""
      echo "  ai-help \"check disk space\""
      echo ""
      echo "This script provides one-line command answers without explanations."
      echo "Commands are automatically copied to clipboard."
  }

  # Check if question is provided
  if [[ $# -eq 0 ]]; then
      print_error "No question provided"
      echo ""
      show_usage
      exit 1
  fi

  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
      show_usage
      exit 0
  fi

  QUESTION="$*"

  # System prompt for command assistance
  SYSTEM_PROMPT="You are a Linux command-line expert working on a NixOS system. Provide ONLY the exact command without any explanation. Use the most practical and modern Linux commands with appropriate flags. For file operations, prefer modern tools. For system info, use standard Linux commands. For package management on NixOS, use 'nix shell' or 'nix run' commands. Always provide complete, ready-to-use commands. If multiple commands are needed, separate them with &&. Respond with ONLY the command, no explanation or extra text."

  # Call ai-ask with system prompt and copy to clipboard
  exec ai-ask -c -s "$SYSTEM_PROMPT" "$QUESTION"
''

