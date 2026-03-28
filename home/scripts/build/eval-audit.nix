{ pkgs, ... }:

pkgs.writeShellScriptBin "eval-audit" (builtins.readFile ../../../scripts/build/eval-audit.sh)
