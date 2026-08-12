# NOTE: zcode.nix (ZCode Desktop App) is NOT imported here.
# It lives in ai-agents/zcode-package.nix and is imported directly
# by ai-agents/services.nix for conditional enablement via cfg.zcode.enable.

{
  pkgs,
  pkgsStable,
  constants,
}:

builtins.concatLists (
  map (f: import f { inherit pkgs pkgsStable constants; }) [
    ./antigravity-cli.nix
    ./orca.nix
    ./t3code.nix
    ./tabby.nix
  ]
)
