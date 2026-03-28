{ pkgs, ... }:

pkgs.writeShellScriptBin "hardening-audit" (
  builtins.readFile ../../../scripts/build/systemd-hardening-audit.sh
)
