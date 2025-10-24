{ pkgs, pkgsStable }:

(with pkgsStable; [
  gcc # C/C++ compiler
  cmake # C/C++ build system
])

++ (with pkgs; [
  rustc # Rust compiler
  cargo # Rust package manager
  sqlite # SQLite database
  just # Justfile runner
  lua-language-server # Lua language server
  stylua # Lua formatter
  nil # Nix language server
  nixpkgs-fmt # Nix formatting
  bruno # API Client
])
