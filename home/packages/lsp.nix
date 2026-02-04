# Language Server Protocol (LSP) servers for code intelligence,
# completion, diagnostics, and navigation in various editors.
{pkgs, ...}:
with pkgs; [
  # === Markup and Data Formats ===
  yaml-language-server # YAML schema validation and completion
  vscode-langservers-extracted # JSON, HTML, CSS, ESLint language servers
  taplo # TOML language server with formatting
  marksman # Markdown language server with wiki-links support

  # === Configuration and DevOps ===
  dockerfile-language-server # Dockerfile language support
  bash-language-server # Bash/Shell script language server

  # === Scripting Languages ===
  lua-language-server # Lua language server (sumneko)

  # === Nix ===
  nil # Nix language server with completion and diagnostics
  nixd # Nix language server with nixpkgs integration
]
