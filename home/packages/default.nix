{
  pkgs,
  pkgsStable,
}: let
  chunks = [
    ./hyprland.nix
    ./cli.nix
    ./cool.nix
    ./development.nix
    ./applications.nix
    ./multimedia.nix
    ./networking.nix
    ./utilities.nix
    ./fonts.nix
    ./privacy.nix
    ./lsp.nix
  ];
in
  # Import each chunk with both pkgs & pkgsStable, then flatten into one big list
  builtins.concatLists (map (f: import f {inherit pkgs pkgsStable;}) chunks)
