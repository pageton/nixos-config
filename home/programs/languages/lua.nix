# Lua development environment (LuaJIT runtime).
# LSP (lua-language-server) lives in lsp-servers.nix; formatter (stylua) in nvf.

{ pkgs, ... }:

{
  home.packages = with pkgs; [
    luajit # LuaJIT 2.1 interpreter (provides both `lua` and `luajit` binaries)
  ];
}
