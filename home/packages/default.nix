# User packages — aggregated from categorized chunk files.
# Each chunk receives { pkgs, pkgsStable, constants } and returns a flat package list.
{
  pkgs,
  pkgsStable,
  constants,
}:
let
  chunks = [
    ./cli.nix
    ./cool.nix
    ./development.nix
    ./applications.nix
    ./multimedia.nix
    ./networking.nix
    ./utilities.nix
    ./wayland.nix
    ./privacy.nix
    ./linting.nix
    ./system-monitoring.nix
    ./productivity.nix
    ./custom/default.nix
  ];
in
# Import each chunk with both pkgs & pkgsStable, then flatten into one big list
builtins.concatLists (map (f: import f { inherit pkgs pkgsStable constants; }) chunks)
