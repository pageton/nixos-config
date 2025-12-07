{
  pkgs,
  pkgsStable,
}:
(with pkgsStable; [
  gcc # C/C++ compiler
  cmake # C/C++ build system
])
++ (with pkgs; [
  rustc # Rust compiler
  cargo # Rust package manager
  rust-analyzer # Rust language server
  clippy # Rust linter
  rustfmt # Rust formatter
  sqlite # SQLite database
  just # Justfile runner
  lua-language-server # Lua language server
  stylua # Lua formatter
  nil # Nix language server
  nixpkgs-fmt # Nix formatting
  bruno # API Client
  burpsuite
  # Container and orchestration tools
  docker-compose # Docker container orchestration
  docker # Docker CLI
  cmake # C/C++ build system
  gdb # C/C++ debugger
])
