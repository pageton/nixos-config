# Language servers for editor integration.
# CLI-only linting/formatting tools live in packages/linting.nix.

{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # === Nix ===
    nil # Nix language server with completion and diagnostics
    nixd # Nix language server with nixpkgs integration

    # === Scripting Languages ===
    bash-language-server # Bash/Shell script language server
    lua-language-server # Lua language server (sumneko)
    pyright # Python type-checking LSP (completions + diagnostics)
    svelte-language-server # Svelte framework

    # === Markup and Data Formats ===
    yaml-language-server # YAML schema validation and completion
    vscode-langservers-extracted # JSON, HTML, CSS, ESLint language servers
    taplo # TOML language server with formatting
    marksman # Markdown language server with wiki-links support

    # === Configuration and DevOps ===
    dockerfile-language-server # Dockerfile language support
    docker-compose-language-service # docker-compose.yml support

    # === Systems Languages ===
    clang-tools # C/C++ LSP (clangd) + formatter (clang-format)
    rust-analyzer # Rust support

    # === Data ===
    sqls # SQL language server (Postgres, MySQL, SQLite)
  ];
}
