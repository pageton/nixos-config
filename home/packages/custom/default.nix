{
  pkgs,
  pkgsStable,
  constants,
}:

builtins.concatLists (
  map (f: import f { inherit pkgs pkgsStable constants; }) [ ./antigravity-cli.nix ]
)
