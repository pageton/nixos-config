{ pkgs, ... }:

pkgs.writeShellScriptBin "performance-audit" (
  builtins.readFile ../../../scripts/build/performance-audit.sh
)
