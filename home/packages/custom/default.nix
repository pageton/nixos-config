# NOTE: zcode.nix and antigravity-cli.nix are NOT imported here.
# They come from the llm-agents flake input via home/ai/default.nix.

{
  pkgs,
  pkgsStable,
  constants,
}:

builtins.concatLists (
  map (f: import f { inherit pkgs pkgsStable constants; }) [
    ./orca.nix
    ./tabby.nix
  ]
)
