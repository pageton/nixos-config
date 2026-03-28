{ pkgs, ... }:

pkgs.writeShellScriptBin "modules-check" (builtins.readFile ../../../scripts/build/modules-check.sh)
