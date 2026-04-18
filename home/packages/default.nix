# User packages — aggregated from categorized chunk files.
# Each chunk receives { pkgs, pkgsStable } and returns a flat package list.
# The lists are concatenated into home.packages by core.nix.
{ pkgs, pkgsStable }:
let
  chunks = [
    ./cli.nix
    ./cool.nix
    ./development.nix
    ./applications.nix
    ./multimedia.nix
    ./networking.nix
    ./utilities.nix
    ./niri.nix
    ./privacy.nix
    ./linting.nix
    ./system-monitoring.nix
    ./productivity.nix
  ];
in
# Import each chunk with both pkgs & pkgsStable, then flatten into one big list
builtins.concatLists (map (f: import f { inherit pkgs pkgsStable; }) chunks)
