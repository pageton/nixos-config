{
  pkgs,
  pkgsStable,
}: let
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
    ./lsp.nix
    ./system-monitoring.nix
  ];
in
  # Import each chunk with both pkgs & pkgsStable, then flatten into one big list
  builtins.concatLists (map (f: import f {inherit pkgs pkgsStable;}) chunks)
