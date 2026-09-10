# Zig development environment (Zig compiler + build system).
# LSP (zls) lives in lsp-servers.nix; formatter (`zig fmt`) is built in.

{ pkgs, ... }:

let
  mkShellAliasPrograms = import ../../_helpers/_shell-alias-programs.nix;
in
{
  programs = mkShellAliasPrograms {
    shellAliases = {
      zigb = "zig build";
      zigr = "zig run";
      zigt = "zig test";
      zigf = "zig fmt";
    };
  };

  home.packages = with pkgs; [ zig ];
}
