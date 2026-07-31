{
  pkgs,
  pkgsStable,
  constants,
}:

builtins.concatLists (
  map (f: import f { inherit pkgs pkgsStable constants; }) [ ./antigravity-cli.nix ./orca.nix ./t3code.nix ]
)
