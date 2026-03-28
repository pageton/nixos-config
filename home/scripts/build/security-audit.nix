{ pkgs, ... }:

pkgs.writeShellScriptBin "security-audit" (
  builtins.readFile ../../../scripts/build/security-audit.sh
)
